# frozen_string_literal: true

class ATS::PlacementsController < ApplicationController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action :set_placement, only: %i[destroy change_status change_stage]

  def create
    case Placements::Add.new(
      candidate_id: params[:candidate_id],
      position_id: params.require(:placement_position_id),
      actor_account: current_account
    ).call
    in Success[placement]
      render_placements_notes_panel(placement)
    in Failure[:placement_invalid, error]
      render_error error, status: :unprocessable_entity
    end
  end

  def destroy
    case Placements::Destroy.new(
      placement: @placement,
      actor_account: current_account
    ).call
    in Success[placement]
      render_placements_notes_panel(placement)
    in Failure[:placement_invalid, error]
      render_error error, status: :unprocessable_entity
    end
  end

  def change_stage
    new_stage = params.require(:stage)
    return unless new_stage.in?(@placement.stages)

    case Placements::ChangeStage.new(
      new_stage:,
      placement: @placement,
      actor_account: current_account
    ).call
    in Success(placement)
      render_placements_notes_panel(placement)
    in Failure[:placement_invalid, error]
      render_error error
    end
  end

  def change_status
    new_status = params.require(:status)

    case Placements::ChangeStatus.new(
      new_status:,
      placement: @placement,
      actor_account: current_account
    ).call
    in Success(placement)
      render_placements_notes_panel(placement)
    in Failure[:placement_invalid, error]
      render_error error
    end
  end

  private

  def set_placement
    @placement = Placement.find(params[:id])
  end

  # rubocop:disable Naming/AccessorMethodName
  def set_placements_variables(placement)
    # TODO: order by placement changed events
    all_placements = placement.candidate.placements.includes(:position_stage, :position)

    @irrelevant_placements = all_placements.filter(&:disqualified?)
    @relevant_placements = all_placements - @irrelevant_placements
  end
  # rubocop:enable Naming/AccessorMethodName

  def render_placements_notes_panel(placement)
    set_placements_variables(placement)

    partial = "ats/candidates/placements_notes_panel"
    locals = {
      candidate: placement.candidate,
      relevant_placements: @relevant_placements,
      irrelevant_placements: @irrelevant_placements
    }

    render_turbo_stream(
      [
        turbo_stream.replace("turbo_placements_notes_panel", partial:, locals:)
      ]
    )
  end
end
