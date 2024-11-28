# frozen_string_literal: true

class Candidates::UploadPDFFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional, optional: true
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }
  option :source, Types::Strict::String.optional, default: proc { "" }
  option :namespace, Types::Strict::Symbol

  def call
    text_checksum =
      Digest::MD5.hexdigest(CVParser::Parser.retrieve_plain_text_from_pdf(file.tempfile))
    # Retrieving the existing CV file should be done before uploading a new file.
    # Otherwise `candidate.cv` will raise an error.
    existing_cv_file = candidate.cv

    case find_existing_same_file(candidate:, text_checksum:, source:)
    in Success(attachment)
      if cv
        mark_attachment_as_cv(attachment:, existing_cv_file:, actor_account:, source:, namespace:)
      end
      return Failure(:file_already_present)
    in Failure(:no_existing_same_file)
      nil
    end

    ActiveRecord::Base.transaction do
      attachment = yield upload_file(candidate:, file:, text_checksum:, source:)
      if cv
        mark_attachment_as_cv(attachment:, existing_cv_file:, actor_account:, source:, namespace:)
      end
      add_event(attachment:, file:, actor_account:)
    end

    Success()
  end

  private

  def find_existing_same_file(candidate:, text_checksum:, source:)
    existing_same_file = candidate.files.find do |attachment|
      custom_metadata = attachment.blob.custom_metadata
      custom_metadata[:text_checksum] == text_checksum && custom_metadata[:source] == source
    end

    return Failure(:no_existing_same_file) if existing_same_file.blank?

    Success(existing_same_file)
  end

  def upload_file(candidate:, file:, text_checksum:, source:)
    attachment = candidate.files.attach(file).attachments.last
    attachment.blob.custom_metadata = { text_checksum:, source: }
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

  def mark_attachment_as_cv(attachment:, existing_cv_file:, actor_account:, source:, namespace:)
    if namespace == :api &&
       existing_cv_file &&
       existing_cv_file.blob.custom_metadata[:source] != source
      return
    end

    return if existing_cv_file == attachment

    attachment.change_cv_status(actor_account)
  end
end
