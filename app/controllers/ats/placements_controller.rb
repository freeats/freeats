# frozen_string_literal: true

class ATS::PlacementsController < ApplicationController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action :set_placement, only: %i[destroy change_status change_stage]

  def create
    case Placements::Add.new(
      params: placement_params.to_h.deep_symbolize_keys,
      create_duplicate_placement: params["placement_already_exists_modal"] == "1",
      actor_account: current_account
    ).call
    in Success[placement]
      render_placements_notes_panel(placement)
    in Failure[:placement_already_exists, placement]
      partial_name = "placement_already_exists_modal"
      modal_render_options = {
        partial: "ats/candidates/#{partial_name}",
        layout: "modal",
        locals: {
          modal_id: partial_name.dasherize,
          form_options: {
            url: ats_candidate_placements_path(placement.candidate),
            method: :post
          },
          hidden_fields: {
            partial_name => "1",
            candidate_id: placement.candidate_id,
            position_id: placement.position_id
          },
          modal_size: "modal-lg",
          placement:,
          candidate_name: placement.candidate.full_name,
          position_name: placement.position.name,
          # TODO: use placement added event
          date_when_assigned: placement.created_at,
          stage: placement.stage,
          reason: placement.position.change_status_reason
        }
      }
      render(modal_render_options)
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

  def placement_params
    return @placement_params if @placement_params.present?

    @placement_params =
      params
      .permit(
        :position_id,
        :candidate_id
      )

    @placement_params
  end
end
