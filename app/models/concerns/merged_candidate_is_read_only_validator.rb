# frozen_string_literal: true

class MergedCandidateIsReadOnlyValidator < ActiveModel::Validator
  def validate(record)
    if record.respond_to?(:taskable_id)
      return unless record.taskable_type == "Candidate"

      candidate = record.taskable
    elsif record.respond_to?(:notable_id)
      return unless record.notable_type == "Candidate"

      candidate = record.notable
    else
      candidate = record.try(:candidate)
      return unless candidate
    end

    if candidate.nil?
      record.errors.add(:base, "Candidate must exist.")
      return
    end
    return if candidate.merged_to.nil?

    record.errors.add(:base, "You are not allowed to perform any actions with merged candidate.")
  end
end
