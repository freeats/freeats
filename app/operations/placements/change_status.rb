# frozen_string_literal: true

class Placements::ChangeStatus < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :new_status, Types::Strict::String
  option :placement, Types::Instance(Placement)
  option :actor_account, Types::Instance(Account).optional, optional: true

  def call
    old_status = placement.status

    return Success(placement) if old_status == new_status

    placement.status = new_status

    placement_changed_params = {
      actor_account:,
      type: :placement_changed,
      eventable: placement,
      performed_at: Time.zone.now,
      changed_field: :status,
      changed_from: old_status,
      changed_to: new_status
    }

    ActiveRecord::Base.transaction do
      yield save_placement(placement)
      yield add_event(placement_changed_params)
    end

    Success(placement)
  end

  private

  def save_placement(placement)
    placement.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:placement_invalid, placement.errors.full_messages.presence || e.to_s]
  end

  def add_event(params)
    Event.create!(params)

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:event_invalid, e.to_s]
  end
end
