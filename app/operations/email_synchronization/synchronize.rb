# frozen_string_literal: true

class EmailSynchronization::Synchronize
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :imap_accounts, [Types::Instance(Imap::Account)]
    option :only_for_email_addresses, [Types::Strict::String], default: proc { [] }
  end

  BATCH_SIZE = 50

  def call
    if only_for_email_addresses.present?
      Imap::Message.message_batches_related_to(
        only_for_email_addresses,
        from_accounts: imap_accounts,
        batch_size: BATCH_SIZE
      ).each do |message_batch|
        message_batch.each do |message|
          process_single_message(message)
        end
      end
    else
      Imap::Message.new_message_batches(
        from_accounts: imap_accounts,
        batch_size: BATCH_SIZE
      ).each do |message_batch|
        message_batch.each do |message|
          process_single_message(message)
        end
      end
    end

    Member::EmailAddress.postprocess_imap_accounts(imap_accounts)

    Success()
  end

  private

  def process_single_message(message)
    logger = ATS::Logger.new(
      where: "EmailSynchronization::Synchronize#process_single_message #{message.message_id}"
    )
    extra = message.to_debug_hash
    result = EmailSynchronization::ProcessSingleMessage.new(message:).call
    case result
    in Failure(:message_already_exists) | Success() | Failure(:not_relevant_message) |
      Failure(:member_is_cc_or_bcc) | Failure(:draft_message)
      nil
    in Success[:with_log_report, payload]
      logger.error(payload[:error_name], **extra.merge(payload.except(:error_name)))
    in Failure(:no_from_addresses)
      logger.error("Received a message with no 'from' addresses", **extra)
    in Failure(:no_to_addresses)
      logger.error("Received a message with no 'to' addresses", **extra)
    in Failure(:message_does_not_contain_member_email_addresses)
      logger.error("Received a message with no member addresses at all", **extra)
    in Failure(:bad_threading)
      logger.error("Failed to thread a message", **extra)
    in Failure[:no_candidate_participants, payload]
      logger.error(
        "Received a message in thread with no person participants",
        **extra.merge(payload)
      )
    end
  rescue StandardError, ActiveRecord::RecordInvalid => e
    logger.error(e, **extra)
  end
end
