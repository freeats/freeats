# frozen_string_literal: true

class ATS::PositionsController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  TABS = %w[
    Info
    Pipeline
    Tasks
    Activities
  ].freeze
  ACTIVITIES_PAGINATION_LIMIT = 25
  BATCH_SIZE_OF_PLACEMENTS_PER_COLUMN = 15

  before_action { @nav_item = :positions }
  before_action :set_position,
                only: %i[show update_side_header show_header edit_header update_header
                         show_card edit_card update_card change_status destroy]
  before_action :set_tabs, only: :show
  helper_method :position_status_options
  before_action :authorize!, only: %i[create new index]
  before_action -> { authorize!(@position) },
                only: %i[show destroy update_side_header show_card edit_card
                         update_card show_header edit_header update_header change_status]
  def index
    @positions_grid_params =
      params[:ats_positions_grid]
      &.to_unsafe_h
      &.symbolize_keys
      &.filter { |k, _v| ATS::PositionsGrid.datagrid_attributes.include?(k) } || {}
    @positions_grid =
      ATS::PositionsGrid.new(@positions_grid_params.merge(current_account:)) do |scope|
        scope.order("color_code ASC")
      end

    positions = @positions_grid.assets.unscope(:order)
    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT COUNT(DISTINCT positions.id)
        FROM (#{positions.unscope(:includes).reselect('positions.*').to_sql}) AS positions
      SQL
    ).rows.first.tap do |pos_count, _|
      @positions_stats = {
        positions: pos_count
      }
    end
    @positions_grid.scope { |scope| scope.page(params[:page]) }
    @positions_grid_assets = @positions_grid.assets.order(:name)
  end

  def show
    set_side_header_predefined_options

    case @active_tab
    when "pipeline"
      set_pipeline_variables
    when "tasks"
      @lazy_load_form_url =
        if params[:task_id]
          if params[:task_id] == "new"
            new_modal_ats_tasks_path(
              params: { taskable_id: @position.id, taskable_type: @position.class.name }
            )
          else
            show_modal_ats_task_path(params[:task_id], grid: :profiles)
          end
        end
      @tasks_grid = ATS::ProfileTasksGrid.new(
        helpers.add_default_sorting(params[:ats_profile_tasks_grid], :due_date, :desc)
      )
      @tasks_grid.scope { _1.where(taskable: @position).page(params[:page]).per(10) }
    when "activities"
      set_activities_variables
    end

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
    case Positions::Add.new(
      params: position_params.to_h.deep_symbolize_keys,
      actor_account: current_account
    ).call
    in Success[position]
      warnings = position.warnings.full_messages

      redirect_to tab_ats_position_path(position, :info),
                  notice: t("positions.successfully_created"),
                  warning: warnings.presence
    in Failure[:position_invalid, _error] | Failure[:position_stage_invalid, _error]
      render_error _error
    end
  end

  def destroy
    if @position.remove
      redirect_to ats_positions_path, notice: t("positions.succesfully_deleted")
      return
    end

    render_error @position.errors.full_messages
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

    result =
      case card_name
      when "pipeline"
        Positions::ChangeStages.new(
          position: @position,
          stages_attributes: position_params[:stages_attributes].to_h.deep_symbolize_keys,
          actor_account: current_account
        ).call
      else
        Positions::Change.new(
          position: @position,
          params: position_params.to_h.deep_symbolize_keys,
          actor_account: current_account
        ).call
      end

    case result
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
            :location_id,
            :recruiter_id,
            :description,
            stages_attributes: {},
            collaborator_ids: [],
            hiring_manager_ids: [],
            interviewer_ids: []
          )
  end

  def set_tabs
    @tabs = TABS.index_by { _1.parameterize(separator: "_") }
    @active_tab ||=
      if @tabs.key?(params[:tab])
        params[:tab]
      elsif params[:task_id]&.match?(/(new|\d+)$/)
        "tasks"
      else
        @tabs.keys.first
      end
    @pending_tab_tasks_count = Task.where(taskable: @position).open.size
  end

  def set_position
    @position =
      Position.includes(stages: :scorecard_template).find(params[:id] || params[:position_id])
  end

  def position_status_options(position)
    statuses = Position.statuses.keys - [position.status]
    statuses.map { |status| [status.humanize, status] }
  end

  def set_side_header_predefined_options
    alphabetically_ordered_members =
      Member
      .order("accounts.name")

    @options_for_collaborators =
      alphabetically_ordered_members
      .where.not(id: @position.recruiter_id)
      .where(access_level: Position::COLLABORATORS_ACCESS_LEVEL)
      .map do |member|
        compose_options_for_select(member, :collaborator_ids)
      end

    @options_for_hiring_managers =
      alphabetically_ordered_members
      .where(access_level: Position::HIRING_MANAGERS_ACCESS_LEVEL)
      .map do |member|
        compose_options_for_select(member, :hiring_manager_ids)
      end

    @options_for_interviewers =
      alphabetically_ordered_members
      .where(access_level: Position::INTERVIEWERS_ACCESS_LEVEL)
      .map do |member|
        compose_options_for_select(member, :interviewer_ids)
      end
  end

  def compose_options_for_select(member, field_name)
    {
      text: member.account.name,
      value: member.id,
      selected: @position.public_send(field_name)&.include?(member.id)
    }
  end

  def set_pipeline_variables
    @placement_limit = BATCH_SIZE_OF_PLACEMENTS_PER_COLUMN
    total_placements = placements =
      if params[:assigned_only]
        @position.total_placements(recruiter_id: current_member.id)
      else
        @position.total_placements
      end
    placements =
      case params[:pipeline_tab]
      when "reserved"
        placements.where(status: :reserved)
      when "disqualified"
        placements.where.not(status: %i[reserved qualified])
      else
        placements.where(status: :qualified)
      end

    @stages = @position.stages.pluck(:name)
    @grouped_placements = {}
    @stages.each { |stage| @grouped_placements[stage] = { count: 0, placements: [] } }
    placements
      .join_last_placement_added_or_changed_event
      .order("events.performed_at DESC")
      .group_by(&:stage).each do |stage, stage_placements|
      @grouped_placements[stage][:count] = stage_placements.size
      @grouped_placements[stage][:placements] = stage_placements.first(@placement_limit)
    end
    @qualified_count = total_placements.where(status: :qualified).count
    @reserved_count = total_placements.where(status: :reserved).count
    @disqualified_count = total_placements.where.not(status: %i[qualified reserved]).count
  end

  def set_activities_variables
    @activities =
      @position
      .events
      .union(
        Event
        .joins(<<~SQL)
          JOIN scorecard_templates ON scorecard_templates.id = events.eventable_id
          JOIN position_stages ON position_stages.id = scorecard_templates.position_stage_id
        SQL
        .where(eventable_type: "ScorecardTemplate")
        .where(position_stages: { position_id: @position.id })
      )
      .union(
        Event
        .joins(<<~SQL)
          JOIN position_stages ON position_stages.id = events.eventable_id
        SQL
        .where(eventable_type: "PositionStage")
        .where(position_stages: { position_id: @position.id })
      )
      .union(
        Event
        .where(eventable_type: "Task")
        .where(eventable_id: @position.tasks.ids)
        .where(type: Event::TASK_TYPES_FOR_PROFILE_ACTIVITY_TAB)
      )
      .includes(
        :removed_stage,
        eventable: :stages_including_deleted,
        actor_account: :member,
        assigned_member: :account,
        unassigned_member: :account
      )
      .order(performed_at: :desc)
      .page(params[:page])
      .per(ACTIVITIES_PAGINATION_LIMIT)
  end
end
