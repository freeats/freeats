# frozen_string_literal: true

class Candidates::UploadFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }
  option :source, Types::Strict::String.optional, default: proc {}

  def call
    case find_existing_same_file(candidate:, file:, source:)
    in Success(existing_same_file)
      mark_file_as_cv(file: existing_same_file, candidate:, actor_account:, source:) if cv
      return Failure[:file_already_present] ## handle this case on level above
    in Failure[:no_existing_same_file]
      nil
    end

    ActiveRecord::Base.transaction do
      attachment = yield upload_file(candidate:, file:)
      mark_file_as_cv(file: attachment, candidate:, actor_account:, source:) if cv
      add_event(attachment:, file:, actor_account:)
    end

    Success()
  end

  private

  def find_existing_same_file(candidate:, file:, source:)
    text_checksum = Digest::MD5.hexdigest(CVParser::Parser.parse_pdf(file.tempfile))

    existing_same_file = candidate.files.find do |attachment|
      custom_metadata = attachment.blob.custom_metadata
      custom_metadata[:text_checksum] == text_checksum && custom_metadata[:source] == source
    end

    return Failure[:no_existing_same_file] if existing_same_file.blank?

    Success(existing_same_file)
  end

  def upload_file(candidate:, file:)
    text_checksum = Digest::MD5.hexdigest(CVParser::Parser.parse_pdf(file.tempfile))
    attachment = candidate.files.attach(file).attachments.last
    attachment.blob.custom_metadata = { text_checksum: }

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

  def mark_file_as_cv(file:, candidate:, actor_account:, source:)
    existing_cv_file = candidate.cv

    if existing_cv_file &&
       existing_cv_file.blob.custom_metadata[:source] == source &&
       existing_cv_file != file
      return
    end

    file.change_cv_status(actor_account)
  end
end
