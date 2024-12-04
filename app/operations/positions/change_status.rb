# frozen_string_literal: true

class Positions::ChangeStatus < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :position, Types::Instance(Position)
  option :actor_account, Types::Instance(Account)
  option :new_status, Types::Strict::String
  option :new_change_status_reason, Types::Strict::String
  option :comment, Types::Strict::String

  def call
    old_status = position.status

    return Success(position) if old_status == new_status
    return Failure(:invalid_status) if new_status == "draft"

    position.change_status_reason = new_change_status_reason
    position.status = new_status

    position_changed_params = {
      actor_account:,
      type: :position_changed,
      eventable: position,
      changed_field: :status,
      changed_from: old_status,
      changed_to: new_status,
      properties: {
        comment:,
        change_status_reason: new_change_status_reason
      }
    }

    ActiveRecord::Base.transaction do
      yield save_position(position)
      disqualify_not_hired_placements(position:, actor_account:) if new_status == "closed"
      requalify_not_hired_placements(position:, actor_account:) if old_status == "closed"
      Event.create!(position_changed_params)
    end

    Success(position)
  end

  private

  def save_position(position)
    position.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:position_invalid, position.errors.full_messages.presence || e.to_s]
  end

  def disqualify_not_hired_placements(position:, actor_account:)
    placements_to_disqualify = position.placements_to_disqualify_on_closing

    return Success() if placements_to_disqualify.blank?

    position_closed_reason = DisqualifyReason.find_by(title: "Position closed")

    placements_to_disqualify.each do |placement|
      yield Placements::ChangeStatus.new(
        new_status: "disqualified",
        disqualify_reason_id: position_closed_reason.id,
        placement:,
        actor_account:
      ).call
    end

    Success()
  end

  def requalify_not_hired_placements(position:, actor_account:)
    placements_to_requalify = position.placements_to_requalify_on_reopening

    return Success() if placements_to_requalify.blank?

    position_recruiter = position.recruiter
    position_recruiter_is_active =
      position_recruiter.present? && position_recruiter.access_level != "inactive"

    placements_to_requalify.each do |placement|
      yield Placements::ChangeStatus.new(
        new_status: "qualified",
        placement:,
        actor_account:
      ).call

      candidate = placement.candidate
      next if !position_recruiter_is_active || candidate.recruiter_id.present?

      yield Candidates::Change.new(
        candidate:,
        actor_account:,
        params: {
          recruiter_id: position_recruiter.id
        }
      ).call
    end

    Success()
  end
end
