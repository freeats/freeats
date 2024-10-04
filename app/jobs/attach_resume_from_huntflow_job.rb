# frozen_string_literal: true

class AttachResumeFromHuntflowJob < ApplicationJob
  def perform(candidate_id:, hf_external_id:)
    candidate = Candidate.find_by(id: candidate_id)

    return unless candidate

    binary_file = Huntflow::Candidate.get_resume(
      candidate_id: candidate.external_source_id,
      external_id: hf_external_id
    )

    filename = "resume_#{hf_external_id}.pdf"
    file_io = StringIO.new(binary_file)

    ActiveRecord::Base.transaction do
      attachment =
        candidate
        .files
        .attach(io: file_io, filename:)
        .attachments
        .last

      Event.create!(
        type: :active_storage_attachment_added,
        eventable: attachment,
        properties: { name: filename }
      )
    end
  end
end
