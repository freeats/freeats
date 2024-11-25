# frozen_string_literal: true

class Candidates::UploadFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }
  option :source, Types::Strict::String.optional, default: proc {}

  def call
    case compare_with_existing_files(candidate:, file:, source:)
    in Failure[:file_already_present, existing_same_file]
      existing_cv_file = candidate.cv

      existing_cv_file_is_different_but_from_same_source =
        existing_cv_file &&
        existing_cv_file.blob.custom_metadata[:source] == source &&
        existing_cv_file != existing_same_file

      if cv && (!existing_cv_file || existing_cv_file_is_different_but_from_same_source)
        existing_same_file.change_cv_status(actor_account)
      end

      return Failure[:file_already_present]
    in Success()
      nil
    end

    ActiveRecord::Base.transaction do
      attachment = yield upload_file(candidate:, file:, cv:)
      add_event(attachment:, file:, actor_account:)
    end

    Success()
  end

  private

  def compare_with_existing_files(candidate:, file:, source:)
    text_checksum = Digest::MD5.hexdigest(CVParser::Parser.parse_pdf(file.tempfile))

    existing_same_file = candidate.files.find do |attachment|
      custom_metadata = attachment.blob.custom_metadata
      custom_metadata[:text_checksum] == text_checksum && custom_metadata[:source] == source
    end

    return Success() if existing_same_file.blank?

    Failure[:file_already_present, existing_same_file]
  end

  def upload_file(candidate:, file:, cv:)
    text_checksum = Digest::MD5.hexdigest(CVParser::Parser.parse_pdf(file.tempfile))
    attachment = candidate.files.attach(file).attachments.last
    attachment.blob.custom_metadata = { text_checksum: }
    attachment.change_cv_status(actor_account) if cv

    Success(attachment)
  rescue ActiveRecord::RecordInvalid => e
    Failure[:file_invalid, e.to_s]
  end

  def add_event(attachment:, file:, actor_account:)
    properties = { name: file.original_filename }

    Event.create!(
      type: :active_storage_attachment_added,
      eventable: attachment,
      properties:,
      actor_account:
    )
  end
end
