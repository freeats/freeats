# frozen_string_literal: true

class PositionStages::Delete < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :position_stage, Types::Instance(PositionStage)
  option :actor_account, Types::Instance(Account).optional, optional: true
  option :stage_to_move_placements_to, Types::Strict::String.optional, optional: true

  def call
    return Failure(:stage_already_deleted) if position_stage.deleted

    if position_stage.name.in?(Position::DEFAULT_STAGES)
      return Failure(:default_stage_cannot_be_deleted)
    end

    placements_to_move = position_stage.placements
    position = position_stage.position
    scorecard_template = position_stage.scorecard_template
    position_stages_to_update =
      position.stages.filter { _1.list_index > position_stage.list_index }
    position_stage.assign_attributes(deleted: true)

    ActiveRecord::Base.transaction do
      yield save_position_stage(position_stage)

      if scorecard_template.present?
        yield ScorecardTemplates::Destroy.new(scorecard_template:, actor_account:).call
      end

      add_event(position:, position_stage_id: position_stage.id)

      if placements_to_move.present?
        yield move_placements(
          placements: placements_to_move,
          stage: position_stage,
          new_stage_name: stage_to_move_placements_to,
          actor_account:
        )
      end

      position_stages_to_update.each do |stage|
        stage.assign_attributes(list_index: stage.list_index - 1)
        yield save_position_stage(stage)
      end
    end

    Success()
  rescue ActiveRecord::RecordNotDestroyed => e
    Failure[:position_stage_not_deleted, e.record.errors]
  end

  private

  def save_position_stage(position_stage)
    position_stage.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:position_stage_invalid, position_stage.errors.full_messages.presence || e.to_s]
  end

  def add_event(position:, position_stage_id:)
    Event.create!(
      type: :position_stage_removed,
      eventable: position,
      changed_field: "stage",
      changed_from: position_stage_id,
      actor_account:
    )
  end

  def move_placements(placements:, stage:, new_stage_name:, actor_account:)
    if new_stage_name.blank? || !new_stage_name.in?([stage.prev_stage, stage.next_stage])
      return Failure(:new_stage_invalid)
    end

    placements.each do |placement|
      Placements::ChangeStage.new(
        new_stage: new_stage_name,
        placement:,
        actor_account:
      ).call
    end

    Success()
  end
end
