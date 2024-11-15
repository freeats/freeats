# frozen_string_literal: true

class Placements::ChangeStatus < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :new_status, Types::Strict::String.enum(*Placement.statuses.keys)
  option :disqualify_reason_id, Types::Coercible::Integer.optional, optional: true
  option :placement, Types::Instance(Placement)
  option :actor_account, Types::Instance(Account).optional, optional: true

  def call
    old_status = placement.status

    return Success(placement) if old_status == new_status

    placement_changed_params = {
      actor_account:,
      type: :placement_changed,
      eventable: placement,
      changed_field: :status,
      changed_from: old_status,
      changed_to: new_status
    }

    if new_status == "disqualified"
      disqualify_reason = DisqualifyReason.find_by(id: disqualify_reason_id)
      if disqualify_reason.blank?
        return Failure[:disqualify_reason_invalid,
                       I18n.t("candidates.disqualification.reason_not_found")]
      end
      placement_changed_params[:properties] = { reason: disqualify_reason.title }
      placement.disqualify_reason_id = disqualify_reason.id
    else
      placement.disqualify_reason_id = nil
    end

    placement.status = new_status

    ActiveRecord::Base.transaction do
      yield save_placement(placement)
      yield Events::Add.new(params: placement_changed_params).call
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
end
