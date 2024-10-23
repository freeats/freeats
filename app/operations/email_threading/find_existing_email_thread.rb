# frozen_string_literal: true

class EmailThreading::FindExistingEmailThread < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :imap_message, Types::Instance(Imap::Message)

  def call
    # Try to go easy route and find the message current one replies to.
    if imap_message.in_reply_to.present? || imap_message.references.present?
      replied_to_message = EmailMessage.find_by(
        message_id: [imap_message.in_reply_to, imap_message.references.last].compact_blank
      )
      return Success(replied_to_message.email_thread) if replied_to_message.present?
    end

    # Gather existing messages with specified addresses.
    email_messages =
      EmailMessage
      .joins(:email_message_addresses)
      .where(
        <<~SQL,
          email_message_addresses.address
          IN (SELECT unnest(array[?]::citext[]))
        SQL
        imap_message.clean_present_emails
      )
      .select(:id, :subject, :message_id, :references, :in_reply_to, :timestamp)
      .distinct
    email_threading_messages = email_messages.map do |email_message|
      EmailThreading::Thread::Message.new(
        message_id: email_message.message_id,
        in_reply_to: email_message.in_reply_to,
        references: email_message.references,
        sort_field: email_message.timestamp,
        db_id: email_message.id
      )
    end

    # Add our new message to the mix of existing messages.
    unique_id = -1
    email_threading_messages.push(
      EmailThreading::Thread::Message.new(
        message_id: imap_message.message_id || "",
        in_reply_to: imap_message.in_reply_to || "",
        references: imap_message.references || [],
        sort_field: imap_message.timestamp || 0,
        db_id: unique_id
      )
    )

    # Thread all existing message with our new message.
    threads = EmailThreading::Thread.new(email_threading_messages).call

    # Find the thread our message is in.
    thread_with_message = threads.find do |thread|
      thread.find do |message|
        message.db_id == unique_id
      end
    end

    return Failure(:thread_completely_lost_during_threading) if thread_with_message.nil?

    # Our new message does not belong to any existing thread, this is a new thread.
    return Failure(:thread_not_found) if thread_with_message.size == 1

    index_in_thread = thread_with_message.index { _1.db_id == unique_id }
    existing_message_in_thread =
      if index_in_thread.zero?
        # Our new message belongs to an existing thread but it was threaded at the start of the
        # whole thread. This is technically an error condition but our threading algorithm
        # could be not so perfect. We assume that the thread is correct and take the next
        # message in the thread.
        EmailMessage.find(thread_with_message[index_in_thread + 1].db_id)
      else
        # Our new message belongs to an existing thread and we return the thread of the message
        # right before ours.
        EmailMessage.find(thread_with_message[index_in_thread - 1].db_id)
      end

    Success(existing_message_in_thread.email_thread)
  end
end
