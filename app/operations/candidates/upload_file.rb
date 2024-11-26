# frozen_string_literal: true

class Candidates::UploadFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }
  option :source, Types::Strict::String.optional, default: proc { "" }

  def call
    checksum = calculate_checksum(file)
    # Retrieving the existing CV file should be done before uploading a new file.
    # Otherwise `candidate.cv` will raise an error.
    existing_cv_file = candidate.cv

    case find_existing_same_file(candidate:, checksum:, source:)
    in Success(existing_same_file)
      mark_file_as_cv(file: existing_same_file, existing_cv_file:, actor_account:, source:) if cv
      return Failure[:file_already_present]
    in Failure[:no_existing_same_file]
      nil
    end

    ActiveRecord::Base.transaction do
      attachment = yield upload_file(candidate:, file:, checksum:, source:)
      mark_file_as_cv(file: attachment, existing_cv_file:, actor_account:, source:) if cv
      add_event(attachment:, file:, actor_account:)
    end

    Success()
  end

  private

  def calculate_checksum(file)
    if file.content_type == "application/pdf"
      Digest::MD5.hexdigest(CVParser::Parser.parse_pdf(file.tempfile))
    else
      binding.pry
      Digest::MD5.hexdigest(file.read)
    end
  end

  def find_existing_same_file(candidate:, checksum:, source:)
    existing_same_file = candidate.files.find do |attachment|
      custom_metadata = attachment.blob.custom_metadata
      custom_metadata[:checksum] == checksum && custom_metadata[:source] == source
    end

    return Failure[:no_existing_same_file] if existing_same_file.blank?

    Success(existing_same_file)
  end

  def upload_file(candidate:, file:, checksum:, source:)
    attachment = candidate.files.attach(file).attachments.last
    attachment.blob.custom_metadata = { checksum:, source: }
    attachment.blob.save!

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

  def mark_file_as_cv(file:, existing_cv_file:, actor_account:, source:)
    if existing_cv_file &&
       (existing_cv_file.blob.custom_metadata[:source] != source ||
       existing_cv_file == file)
      return
    end

    file.change_cv_status(actor_account)
  end
end
