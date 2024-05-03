# frozen_string_literal: true

class EmailSynchronization::ProcessSingleMessage::StopSequences
  include Dry::Monads[:result]

  include Dry::Initializer.define -> do
    option :email_message, Types::Instance(EmailMessage)
    option :message_member, Types::Instance(EmailSynchronization::MessageMember)
    option :unsuccessful_delivery_reason, Types::Coercible::String.optional
    option :is_auto_replied, Types::Strict::Bool
  end

  def call
    # We use synchronized 'Address not found' messages from mail service addresses
    # to stop sequences.
    if unsuccessful_delivery_reason
      email_message.candidates_in_thread.each do |candidate|
        Candidates::StopSequences.new(
          candidate:,
          with_exited_at: Time.zone.at(email_message.timestamp),
          event_properties: { reason: unsuccessful_delivery_reason }
        ).call.value!
      end

      if unsuccessful_delivery_reason == "address_not_found"
        mark_address_as_outdated_or_invalid(email_message)
      end

      Success(:failed_delivery_sequences_stopped)

    # Auto-reply
    elsif is_auto_replied
      email_message.candidates_in_thread.each do |candidate|
        Candidates::StopSequences.new(
          candidate:,
          with_exited_at: Time.zone.at(email_message.timestamp),
          event_properties: { reason: "auto_reply" }
        ).call.value!
      end

      Success(:auto_reply_sequences_stopped)

    # Got normal response, stopping the sequence.
    else
      email_message.email_thread.candidates_in_thread.each do |candidate|
        Candidates::StopSequences.new(
          candidate:,
          with_status: :replied,
          with_exited_at: Time.zone.at(email_message.timestamp),
          event_properties: { from: email_message.fetch_from_addresses.first }
        ).call.value!
      end

      Success()
    end
  end

  private

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
end
