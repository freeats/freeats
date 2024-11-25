# frozen_string_literal: true

class EmailSynchronization::Synchronize < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :imap_account, Types::Instance(Imap::Account)
  option :only_for_email_addresses, [Types::Strict::String], default: proc { [] }

  BATCH_SIZE = 50

  def call
    if only_for_email_addresses.present?
      Imap::Message.message_batches_related_to(
        only_for_email_addresses,
        from_account: imap_account,
        batch_size: BATCH_SIZE
      ).each do |message_batch|
        message_batch.each do |message|
          process_single_message(message)
        end
      end
    else
      Imap::Message.new_message_batches(
        from_account: imap_account,
        batch_size: BATCH_SIZE
      ).each do |message_batch|
        message_batch.each do |message|
          process_single_message(message)
        end
      end
    end

    Member.postprocess_imap_account(imap_account)

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
       Failure(:draft_message)
      nil
    in Success[:with_log_report, payload]
      logger.error(payload[:error_name], **extra, **payload.except(:error_name))
    in Failure[:email_thread_invalid, error]
      logger.error("Failed to create email_thread", error)
    in Failure(:no_from_addresses)
      logger.error("Received a message with no 'from' addresses", **extra)
    in Failure(:no_to_addresses)
      logger.error("Received a message with no 'to' addresses", **extra)
    in Failure(:message_does_not_contain_member_email_address)
      logger.error("Received a message with no member address at all", **extra)
    in Failure(:bad_threading)
      logger.error("Failed to thread a message", **extra)
    in Failure[:no_candidate_participants, payload]
      logger.error(
        "Received a message in thread with no person participants",
        **extra, **payload
      )
    end
  rescue StandardError, ActiveRecord::RecordInvalid => e
    logger.error(e, **extra)
  end
end
