# frozen_string_literal: true

class ATS::PositionStagesController < AuthorizedController
  include Dry::Monads[:result]

  before_action :set_position_stage, only: :destroy
  before_action -> { authorize!(@position_stage) }, only: %i[destroy]

  def destroy
    partial_name = "delete_stage_modal"
    if params[partial_name] != "1"
      options_for_select = options_for_delete_stage_modal
      modal_render_options = {
        partial: partial_name,
        layout: "modal",
        locals: {
          stage: @position_stage,
          modal_id: partial_name.dasherize,
          form_options: {
            url: ats_position_stage_path(@position_stage),
            method: :delete
          },
          hidden_fields: {
            partial_name => "1"
          },
          options_for_select:
        }
      }
      render(modal_render_options)
    else
      case PositionStages::Delete.new(
        position_stage: @position_stage,
        actor_account: current_account,
        stage_to_move_placements_to: params[:new_stage]
      ).call
      in Success()
        message = t("position_stages.succesfully_deleted")
        turbo_remove_stage = turbo_stream.remove("position_stage#{@position_stage.id}")
        render_turbo_stream([turbo_remove_stage], notice: message)
      in Failure[:position_stage_not_deleted, _error] | Failure[:event_invalid, _error]
        render_error _error, status: :unprocessable_entity
      in Failure(:stage_already_deleted)
        render_error t("position_stages.already_deleted"), status: :unprocessable_entity
      in Failure(:new_stage_invalid)
        render_error t("position_stages.new_stage_deleted"), status: :unprocessable_entity
      in Failure(:default_stage_cannot_be_deleted)
        # should not be possible using our UI.
        render_error t("position_stages.cannot_be_deleted"), status: :unprocessable_entity
      end
    end
  end

  private

  def set_position_stage
    @position_stage = PositionStage.find(params[:id])
  end

  def options_for_delete_stage_modal
    return [] if @position_stage.placements.blank?

    [@position_stage.prev_stage, @position_stage.next_stage].map do |stage|
      { text: stage, value: stage }
    end
  end
end
