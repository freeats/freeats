# frozen_string_literal: true

class EmailSynchronization::ProcessSingleMessage::UploadAttachments < ApplicationOperation
  # Do not include "do" here, apparently it doesn't play nice with file manipulations and
  # causes flaky tests with the error:
  # NoMethodError: super: no superclass method `call'
  include Dry::Monads[:result]

  option :email_message, Types::Instance(EmailMessage)
  option :imap_message, Types::Instance(Imap::Message)

  def call
    # TODO: adapt to new file storage logic.
    upload_imap_attachments(email_message, imap_message)
    create_file_entries(email_message)
    Success()
  end

  private

  def upload_imap_attachments(email_message, imap_message)
    imap_message
      .attachments
      .reject { |attachment| attachment.filename.end_with?(".ics") }
      .each do |attachment|
      Dir.mktmpdir do |dir|
        tmp_file_path = "#{dir}/#{attachment.filename}"
        File.binwrite(tmp_file_path, attachment.decoded)
        File.open(tmp_file_path, "rb") do |f|
          email_message.remote_files.create!(file: f, type: :document)
        end
      end
    end
  end

  def create_file_entries(email_message)
    email_message.email_thread.candidates_in_thread.each do |person|
      email_message.remote_files.each do |remote_file|
        FileEntry.add(
          remote_file:,
          person_id: person.id
        )
      end
    end
  end
end
