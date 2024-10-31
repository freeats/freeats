# frozen_string_literal: true

class ATS::PlacementsController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action :set_placement, only: %i[destroy change_status change_stage]
  before_action :authorize!, only: %i[create]
  before_action -> { authorize!(@placement) },
                only: %i[destroy change_stage change_status]

  def create
    case Placements::Add.new(
      params: placement_params.to_h.deep_symbolize_keys,
      create_duplicate_placement: params["placement_already_exists_modal"] == "1",
      actor_account: current_account
    ).call
    in Success[placement]
      render_placements_panel(placement)
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
          date_when_assigned: placement.added_event.performed_at,
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
      render_placements_panel(placement)
    in Failure[:placement_not_destroyed, error]
      render_error error, status: :unprocessable_entity
    end
  end

  def change_stage
    old_stage = @placement.stage
    new_stage = params.require(:stage)

    position_pipeline_card = params[:position_pipeline_card] == "true"

    case Placements::ChangeStage.new(
      new_stage:,
      placement: @placement,
      actor_account: current_account
    ).call
    in Success(placement)
      if position_pipeline_card
        render_pipeline_card_on_change_stage(old_stage:, new_stage:)
      else
        render_placements_panel(placement)
      end
    in Failure[:placement_invalid, _e]
      render_error _e
    in Failure(:new_stage_invalid)
      render_error t("position_stages.new_stage_deleted"), status: :unprocessable_entity
    end
  end

  def change_status
    old_status = @placement.status
    new_status = params.require(:status)

    position_pipeline_card = params[:position_pipeline_card] == "true"

    case Placements::ChangeStatus.new(
      new_status:,
      placement: @placement,
      actor_account: current_account
    ).call
    in Success(placement)
      if position_pipeline_card
        render_pipeline_card_on_change_status(placement:, old_status:, new_status:)
      else
        render_placements_panel(placement)
      end
    in Failure[:placement_invalid, error]
      render_error error
    end
  end

  def fetch_pipeline_placements
    position = Position.find(params[:position_id])
    placements = position.placements
    placements =
      case params[:pipeline_tab]
      when "reserved"
        placements.where(status: :reserved)
      when "disqualified"
        placements.where.not(status: %i[reserved qualified])
      else
        placements.where(status: :qualified)
      end
    position_stage_id =
      position
      .stages
      .find_by(position_stages: { name: params[:stage] })
      .id
    fetched_placements =
      placements
      .where(position_stage_id:)
      .join_last_placement_added_or_changed_event
      .order("events.performed_at DESC")
      .offset(params[:offset])
      .limit(params[:limit])

    render partial: "ats/placements/placement_pipeline_card", collection: fetched_placements
  end

  private

  def set_placement
    @placement = Placement.find(params[:id])
  end

  # rubocop:disable Naming/AccessorMethodName
  def set_placements_variables(placement)
    candidate = placement.candidate
    all_placements =
      candidate
      .placements
      .select("placements.*, events.performed_at AS added_at")
      .joins(:added_event)
      .includes(:position_stage, :position)

    # Sort by created_at is intentional.
    @irrelevant_placements = all_placements.filter(&:disqualified?).sort_by(&:added_at).reverse
    @relevant_placements = (all_placements - @irrelevant_placements).sort_by(&:added_at).reverse
    @positions_for_quick_assignment = candidate.positions_for_quick_assignment(current_member.id)
  end
  # rubocop:enable Naming/AccessorMethodName

  def render_pipeline_card_on_change_status(placement:, old_status:, new_status:)
    total_placements = placement.position.total_placements
    status_count = lambda do |placement_status|
      case placement_status
      when "qualified"
        total_placements.where(status: :qualified).count
      when "reserved"
        total_placements.where(status: :reserved).count
      else
        total_placements.where.not(status: %i[qualified reserved]).count
      end
    end

    placement_dom_id = ActionView::RecordIdentifier.dom_id(placement)
    current_status_type = %w[qualified reserved].exclude?(new_status) ? "disqualified" : new_status
    current_status_count = status_count.call(new_status)
    old_status_count = status_count.call(old_status)
    old_status_type =
      %w[qualified reserved].exclude?(old_status) ? "disqualified" : old_status
    render_placements = [
      turbo_stream.remove(placement_dom_id),
      turbo_stream.update(
        "turbo_position_pipeline_#{current_status_type}_status_counter",
        current_status_count
      ),
      turbo_stream.update(
        "turbo_position_pipeline_#{current_status_type}_mobile_status_counter",
        current_status_count
      ),
      turbo_stream.update(
        "turbo_position_pipeline_#{old_status_type}_status_counter",
        old_status_count
      ),
      turbo_stream.update(
        "turbo_position_pipeline_#{old_status_type}_mobile_status_counter",
        old_status_count
      ),
      turbo_stream.update_all( # rubocop:disable Rails::SkipsModelValidations
        ".turbo_position_pipeline_#{placement.stage}_stage_counter",
        stage_count(placement.stage, old_status)
      )
    ]

    render_turbo_stream(render_placements)
  end

  def render_pipeline_card_on_change_stage(old_stage:, new_stage:)
    placement_old_dom_id = ActionView::RecordIdentifier.dom_id(@placement)
    placements_dom_id = "turbo_#{new_stage}_stage_placements"
    placements_partial = "ats/placements/placement_pipeline_card"
    placements_locals = { placement_pipeline_card: @placement }

    # rubocop:disable Rails/SkipsModelValidations
    render_placements =
      [
        turbo_stream.remove(placement_old_dom_id),
        turbo_stream.prepend(
          placements_dom_id,
          partial: placements_partial,
          locals: placements_locals
        ),
        turbo_stream.update_all(
          ".turbo_position_pipeline_#{old_stage}_stage_counter",
          stage_count(old_stage, @placement.status)
        ),
        turbo_stream.update_all(
          ".turbo_position_pipeline_#{new_stage}_stage_counter",
          stage_count(new_stage, @placement.status)
        )
      ]
    # rubocop:enable Rails/SkipsModelValidations

    render_turbo_stream([*render_placements])
  end

  def render_placements_panel(placement)
    set_placements_variables(placement)

    partial = "ats/candidates/placements_panel"
    locals = {
      candidate: placement.candidate,
      relevant_placements: @relevant_placements,
      irrelevant_placements: @irrelevant_placements,
      positions_for_quick_assignment: @positions_for_quick_assignment
    }

    render_turbo_stream(
      [
        turbo_stream.replace("turbo_placements_panel", partial:, locals:)
      ]
    )
  end

  def placement_params
    return @placement_params if @placement_params.present?

    @placement_params =
      params
      .permit(
        :position_id,
        :candidate_id,
        :suggestion_disqualify_reason
      )

    @placement_params
  end

  def stage_count(placement_stage, placement_status)
    query =
      @placement
      .position
      .placements
      .joins(:position_stage)
      .where(position_stage: { name: placement_stage })

    query =
      if placement_status.in?(%w[qualified reserved])
        query.where(status: placement_status)
      else
        query.where.not(status: %w[qualified reserved])
      end

    count =
      query
      .join_last_placement_added_or_changed_event
      .order("events.performed_at DESC")
      .group_by(&:stage)[placement_stage]&.size

    count ||= 0

    count
  end
end
