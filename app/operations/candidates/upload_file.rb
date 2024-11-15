# frozen_string_literal: true

class Candidates::UploadFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }

  def call
    properties = { name: file.original_filename }
    ActiveRecord::Base.transaction do
      attachment = candidate.files.attach(file).attachments.last
      yield add_event(attachment:, properties:, actor_account:)
      attachment.change_cv_status(actor_account) if cv
    end

    Success(candidate.files.last)
  rescue ActiveRecord::RecordInvalid => e
    Failure[:file_invalid, e.to_s]
  end

  private

  def add_event(attachment:, properties:, actor_account:)
    Event.create!(
      type: :active_storage_attachment_added,
      eventable: attachment,
      properties:,
      performed_at: Time.zone.now,
      actor_account:
    )

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:event_invalid, e.to_s]
  end
end
