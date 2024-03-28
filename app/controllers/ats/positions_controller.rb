# frozen_string_literal: true

class ATS::PositionsController < ApplicationController
  include Dry::Monads[:result]

  TABS = [
    "Info",
    "Pipeline",
    "Sequence templates",
    "Activities"
  ].freeze
  ACTIVITIES_PAGINATION_LIMIT = 25
  BATCH_SIZE_OF_PLACEMENTS_PER_COLUMN = 15

  before_action { @nav_item = :positions }
  before_action :set_position,
                only: %i[show update_side_header show_header edit_header update_header
                         reassign_recruiter show_card edit_card update_card change_status destroy]
  before_action :set_tabs, only: :show
  helper_method :position_status_options
  def index; end

  def show
    set_side_header_predefined_options

    # case @active_tab
    # when "info"
    # when "pipeline"
    #   set_pipeline_variables
    # when "sequence_templates"
    #   @sequence_templates_grid = ATS::SequenceTemplatesGrid.new do |scope|
    #     scope
    #       .where(sequence_templateable: @position)
    #       .order(:name)
    #       .page(params[:page])
    #       .per(10)
    #   end
    # when "activities"
    #   set_activities_variables
    # end
    render "#{@active_tab}_tab", layout: "ats/position_profile"
  end

  def new
    partial_name = "new_position_modal"
    render(
      partial: partial_name,
      layout: "modal",
      locals: {
        modal_id: partial_name.dasherize,
        form_options: {
          url: ats_positions_path,
          method: :post,
          data: { turbo_frame: "_top" }
        },
        hidden_fields: {
          company_id: params[:company_id]
        }
      }
    )
  end

  def create
    auto_assigned_params = {
      recruiter_id: current_user.member.id,
      company_id: params[:position][:company_id]
    }
    @position = Position.new(position_params.merge(auto_assigned_params))

    if @position.save_new(actor_user: current_user)
      warnings = @position.warnings.full_messages

      redirect_to tab_ats_position_path(@position, :info),
                  notice: "Position draft was successfully created.",
                  warning: warnings.presence
    else
      render_error(@position.errors.full_messages)
    end
  end

  def destroy
    @position.destroy!
    redirect_to ats_positions_path,
                notice: "The position was successfully deleted."
  end

  def update_side_header
    case Positions::Change.new(
      position: @position,
      params: position_params.to_h.deep_symbolize_keys,
      actor_account: current_account
    ).call
    in Failure[:position_invalid, error]
      render_error error, status: :unprocessable_entity
    in Success[_]
      set_side_header_predefined_options
      changed_field = position_params.keys.find do |param|
        param.in?(%w[collaborator_ids])
      end
      render_turbo_stream(
        turbo_stream.replace(
          :side_header,
          partial: "side_header",
          locals: { changed_field: }
        )
      )
    end
  end

  def reassign_recruiter
    case Positions::Change.new(
      position: @position,
      params: position_params.to_h.deep_symbolize_keys,
      actor_account: current_account
    ).call
    in Failure[:position_invalid, error]
      render_error error, status: :unprocessable_entity
    in Success[_]
      locals = {
        currently_assigned_account: @position.recruiter&.account,
        tooltip_title: "Recruiter",
        target_model: @position,
        target_url: reassign_recruiter_ats_position_path(@position),
        input_button_name: "position[recruiter_id]",
        mobile: params[:mobile]
      }
      # rubocop:disable Rails/SkipsModelValidations
      render_turbo_stream(
        turbo_stream.update_all(
          ".turbo_position_reassign_recruiter_button",
          partial: "shared/profile/reassign_button",
          locals:
        )
      )
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  INFO_CARDS = %w[description pipeline].freeze
  private_constant :INFO_CARDS

  def show_card
    card_name = params[:card_name]
    return unless card_name.in?(INFO_CARDS)

    render(
      partial: "ats/positions/info_cards/#{card_name}_show",
      locals: { position: @position, control_button: :edit, namespace: :ats }
    )
  end

  def edit_card
    card_name = params[:card_name]
    return unless card_name.in?(INFO_CARDS)

    render(
      partial: "ats/positions/info_cards/#{card_name}_edit",
      locals: {
        position: @position,
        target_url: update_card_ats_position_path(@position),
        namespace: :ats
      }
    )
  end

  def update_card
    card_name = params[:card_name]
    return unless card_name.in?(INFO_CARDS)

    case Positions::Change.new(
      position: @position,
      params: position_params.to_h.deep_symbolize_keys,
      actor_account: current_account
    ).call
    in Failure[:position_invalid, _error] | Failure[:position_stage_invalid, _error]
      render_error _error, status: :unprocessable_entity
    in Success[_]
      render_turbo_stream(
        turbo_stream.update(
          "turbo_#{card_name}_section",
          partial: "ats/positions/info_cards/#{card_name}_show",
          locals: { position: @position, control_button: :edit, namespace: :ats }
        ),
        warning: @position.warnings.full_messages.uniq.join("<br>")
      )
    end
  end

  def show_header
    render partial: "header_show"
  end

  def edit_header
    render partial: "header_edit"
  end

  def update_header
    case Positions::Change.new(
      position: @position,
      params: position_params.to_h.deep_symbolize_keys,
      actor_account: current_account
    ).call
    in Failure[:position_invalid, error]
      render_error error, status: :unprocessable_entity
    in Success[_]
      render_turbo_stream(
        [turbo_stream.replace(:turbo_header_section, partial: "ats/positions/header_show")]
      )
    end
  end

  def change_status
    partial_name = "change_status_modal"
    new_status = params.require(:new_status)
    if params[partial_name] != "1"
      actual_reasons = Position.const_get("#{new_status.upcase}_REASONS")
      options_for_select =
        Position::CHANGE_STATUS_REASON_LABELS.slice(*actual_reasons).map do |value, text|
          { text:, value: }
        end

      modal_render_options = {
        partial: partial_name,
        layout: "modal",
        locals: {
          position: @position,
          modal_id: partial_name.dasherize,
          form_options: {
            url: change_status_ats_position_path(@position),
            method: :patch
          },
          hidden_fields: {
            partial_name => "1",
            new_status:
          },
          modal_size: "modal-lg",
          options_for_select:,
          new_status:
        }
      }
      render(modal_render_options)
    else
      case Positions::ChangeStatus.new(
        position: @position,
        actor_account: current_account,
        new_status:,
        new_change_status_reason: params[:new_change_status_reason],
        comment: params[:comment]
      ).call
      in Failure[:position_invalid, error]
        render_error error, status: :unprocessable_entity
      in Success[_]
        render_turbo_stream(
          [
            turbo_stream.replace(:turbo_header_section, partial: "ats/positions/header_show")
          ],
          warning: @position.warnings.full_messages.uniq.join("<br>")
        )
      end
    end
  end

  private

  def position_params
    params.require(:position)
          .permit(
            :name,
            :recruiter_id,
            :description,
            stages_attributes: {},
            collaborator_ids: []
          )
  end

  def set_tabs
    @tabs = TABS.index_by { _1.parameterize(separator: "_") }
    # rubocop:disable Naming/MemoizedInstanceVariableName
    @active_tab ||=
      if @tabs.key?(params[:tab])
        params[:tab]
      else
        @tabs.keys.first
      end
    # rubocop:enable Naming/MemoizedInstanceVariableName
  end

  def set_position
    @position = Position.includes(:stages).find(params[:id] || params[:position_id])
  end

  def position_status_options(position)
    statuses = Position.statuses.keys - [position.status]
    statuses.map { |status| [status.humanize, status] }
  end

  def set_side_header_predefined_options
    @active_recruiters =
      Member.includes(:account).active.map { [_1.account.name, _1.id] }

    @options_for_collaborators =
      @active_recruiters.filter { |_, id| id != @position.recruiter_id }.map do |text, value|
        { text:, value:, selected: @position.collaborator_ids&.include?(value) }
      end
  end
end
