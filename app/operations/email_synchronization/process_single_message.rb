# frozen_string_literal: true

class EmailSynchronization::ProcessSingleMessage < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :message, Types::Instance(Imap::Message)

  REPLY_DURATION = 1.hour

  def call
    return Failure(:message_already_exists) if EmailMessage.exists?(message_id: message.message_id)

    yield check_message_from_to_fields_presence(message)
    yield check_message_relevance(message)

    message_member = yield find_member(message)
    email_thread = yield find_existing_email_thread_if_present(message)

    yield check_message_participant_presence(message, email_thread, message_member)

    payload = nil
    email_message = nil
    ActiveRecord::Base.transaction do
      email_thread = yield create_email_thread if email_thread.nil?
      email_message = CreateFromImap.new(
        message:,
        email_thread_id: email_thread.id,
        message_member:,
        sent_via: :gmail
      ).call.value!
      unsuccessful_delivery_reason = message.find_unsuccessful_delivery_reason
      if unsuccessful_delivery_reason == "address_not_found"
        mark_address_as_outdated_or_invalid(email_message)
      end

      timestamp_is_old = old_timestamp?(email_message)

      if message_member.field != :from && !timestamp_is_old
        AdvancePlacementsToRepliedStage.new(email_message:).call.value!
      elsif timestamp_is_old
        Log.tagged("EmailSynchronization::ProcessSingleMessage#call") do |log|
          log.error("Received a message with old timestamp", email_message_id: email_message.id)
        end
      end
    end

    # FIXME
    # UploadAttachments.new(email_message:, imap_message: message).call.value!

    payload ? Success[:with_log_report, payload] : Success()
  end

  private

  def create_email_thread
    email_thread = EmailThread.create!

    Success(email_thread)
  rescue ActiveRecord::RecordInvalid => e
    Failure[:email_thread_invalid, email_thread.errors.full_messages.presence || e.to_s]
  end

  def check_message_from_to_fields_presence(message)
    if message.clean_from_emails.blank?
      Failure(:no_from_addresses)
    elsif message.clean_to_emails.blank?
      Failure(:no_to_addresses)
    else
      Success()
    end
  end

  def check_message_relevance(message)
    is_message_with_existing_addresses = query_existing_contact_addresses(message).present?
    is_message_related_to_existing_thread =
      (message.in_reply_to.present? || message.references.present?) &&
      EmailMessage.exists?(message_id: [message.in_reply_to, message.references.last].compact_blank)

    if !is_message_with_existing_addresses && !is_message_related_to_existing_thread ||
       (message.from_mail_service? || message.to_mail_service?) &&
       !message.failed_delivery?
      Failure(:not_relevant_message)
    else
      Success()
    end
  end

  def find_member(message)
    if (member = Member.find_by_address(message.clean_from_emails))
      Success(EmailSynchronization::MessageMember.new(field: :from, member:))
    elsif (member = Member.find_by_address(message.clean_to_emails))
      Success(EmailSynchronization::MessageMember.new(field: :to, member:))
    elsif (member = Member.find_by_address(message.clean_cc_emails))
      Success(EmailSynchronization::MessageMember.new(field: :cc, member:))
    elsif (member = Member.find_by_address(message.clean_bcc_emails))
      Success(EmailSynchronization::MessageMember.new(field: :bcc, member:))
    else
      Failure(:message_does_not_contain_member_email_address)
    end
  end

  def find_existing_email_thread_if_present(message)
    case EmailThreading::FindExistingEmailThread.new(imap_message: message).call
    in Success(thread)
      Success(thread)
    in Failure(:thread_not_found)
      Success(nil)
    in Failure(:thread_completely_lost_during_threading)
      Failure(:bad_threading)
    end
  end

  def check_message_participant_presence(message, email_thread, message_member)
    are_candidates_in_message_or_thread =
      if email_thread.present?
        email_thread.candidates_in_thread.any?
      else
        Candidate
          .with_emails(message.clean_from_emails + message.clean_to_emails)
          .any?
      end

    # Failed delivery does not need to have any candidate participants.
    if !message.failed_delivery? &&
       !are_candidates_in_message_or_thread
      Failure[:no_candidate_participants, { message_member_id: message_member.member.id }]
    else
      Success()
    end
  end

  def query_existing_contact_addresses(message)
    addresses = message.clean_present_emails.map do |ad|
      Normalizer.email_address(ad)
    end
    addresses.uniq!

    CandidateEmailAddress
      .where(
        <<~SQL,
          candidate_email_addresses.address
          IN (SELECT unnest(array[?]::citext[]))
        SQL
        addresses
      )
      .pluck(:address)
      .uniq
  end

  def mark_address_as_outdated_or_invalid(email_message)
    email_address = email_message.plain_body[CVParser::Content::EMAIL_REGEX]
    return if email_address.blank?

    new_email_addresses_status =
      if EmailMessage.messages_from_addresses(from: email_address).exists?
        :outdated
      else
        :invalid
      end
    CandidateEmailAddress
      .joins(:candidate)
      .where(address: email_address)
      .where(candidate: { merged_to: nil })
      .find_each do |candidate_email_address|
      candidate_email_address.update!(status: new_email_addresses_status)
    end
  end

  def old_timestamp?(email_message)
    if (parent = email_message.find_parent).present?
      email_message.timestamp < parent.timestamp - REPLY_DURATION.to_i
    else
      earliest_message =
        EmailMessage
        .messages_to_addresses(to: email_message.fetch_from_addresses)
        .min_by(&:timestamp)
      if earliest_message.present?
        email_message.timestamp < earliest_message.timestamp - REPLY_DURATION.to_i
      end
    end
  end
end
