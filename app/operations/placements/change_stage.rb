# frozen_string_literal: true

class Placements::ChangeStage
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :new_stage, Types::Strict::String
    option :placement, Types::Instance(Placement)
    option :actor_account, Types::Instance(Account).optional, optional: true
  end

  def call
    old_stage = placement.stage

    return Success(placement) if old_stage == new_stage

    old_stage_id = placement.position_stage_id
    placement.position_stage = placement.position.stages.find_by(name: new_stage)

    return Failure[:new_stage_invalid, "Cannot find stage."] if placement.position_stage.blank?

    placement_changed_params = {
      actor_account:,
      type: :placement_changed,
      eventable: placement,
      changed_field: :stage,
      changed_from: old_stage_id,
      changed_to: placement.position_stage_id
    }

    ActiveRecord::Base.transaction do
      yield save_placement(placement)
      yield Events::Add.new(params: placement_changed_params).call
    end

    Success(placement)
  end

  private

  def save_placement(placement)
    result = Try[ActiveRecord::RecordInvalid] do
      placement.save!
    end.to_result

    case result
    in Success(_)
      Success(placement.reload)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:placement_invalid, placement.errors.full_messages.presence || e.to_s]
    end
  end
end
