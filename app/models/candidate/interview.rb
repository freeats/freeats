# frozen_string_literal: true

# This is `events` table based model which is only concerned with these event types:
# - candidate_interview_resolved
# - candidate_interview_scheduled
class Candidate::Interview < Event
  RESOLVED_STATUSES = %w[
    passed
    failed
    canceled_by_candidate
    canceled_by_recruiter
    missed_by_candidate
    canceled
  ].freeze
  CANCELED_REASONS = {
    "canceled_by_candidate" => "Candidate canceled it",
    "missed_by_candidate" => "Candidate missed it",
    "canceled_by_recruiter" => "I canceled it",
    "canceled" => "Other reason"
  }.freeze

  scope :filter_events,
        -> { where(type: %i[candidate_interview_scheduled candidate_interview_resolved]) }
  scope :upcoming, lambda {
    where(
      "to_timestamp(properties->>'scheduled_for', 'YYYY-MM-DDThh24:mi:ss TZH') > ?",
      Time.zone.now
    )
  }

  before_destroy -> { pair_event&.destroy! }

  def find_resolved_event
    return self if resolved_event?

    Candidate::Interview
      .where("(properties->>'pair_event_id')::bigint = (?)::bigint", id)
      .find_by(type: :candidate_interview_resolved)
  end

  def scheduled_for
    properties["scheduled_for"].to_datetime.in_time_zone if scheduled_event?
  end

  def scheduled_event?
    type == "candidate_interview_scheduled"
  end

  def resolved_event?
    type == "candidate_interview_resolved"
  end

  def pair_event
    if scheduled_event?
      find_resolved_event
    else
      return if properties["pair_event_id"].blank?

      Interview.find_by(id: properties["pair_event_id"])
    end
  end
end
