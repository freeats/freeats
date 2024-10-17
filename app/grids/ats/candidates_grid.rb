# frozen_string_literal: true

class ATS::CandidatesGrid
  include Datagrid

  SELECTED_FIELDS =
    <<~SQL.squish
      candidates.blacklisted,
      candidates.candidate_source_id,
      candidates.company,
      candidates.created_at,
      candidates.id,
      candidates.last_activity_at,
      candidates.location_id,
      candidates.full_name,
      candidates.recruiter_id
    SQL

  #
  # Scope
  #

  scope do
    Candidate
      .not_merged
      .with_attached_avatar
      .select(SELECTED_FIELDS)
  end

  self.batch_size = 500

  attr_accessor :page

  #
  # Filters
  #

  filter(
    :candidate,
    :string,
    header: I18n.t("core.candidate"),
    placeholder: I18n.t("core.search")
  ) do |query|
    search_by_names_or_emails(query).select(SELECTED_FIELDS)
  end

  filter(
    :locations,
    :string,
    multiple: true,
    placeholder: I18n.t("core.location"),
    autocomplete: {
      type: :multiple_locations,
      location_types: %w[country city]
    }
  ) do |location_ids|
    in_location(location_ids)
  end

  filter(
    :position,
    :enum,
    select: lambda {
      Position.order("positions.status ASC, positions.name ASC")
              .pluck(:name, :id)
    },
    include_blank: I18n.t("core.position"),
    placeholder: I18n.t("core.position")
  ) do |position_id|
    joins(:placements).where(placements: { position_id: }).distinct
  end

  filter(
    :stage,
    :enum,
    select: -> {
      PositionStage.group(:name).order("MIN(list_index)").pluck(:name).map { [_1, _1] }
    },
    multiple: true,
    placeholder: I18n.t("core.stage")
  ) do |stage_name|
    joins(placements: :position_stage)
      .where(placements: { position_stages: { name: stage_name } })
      .distinct
  end

  filter(
    :status,
    :enum,
    select: lambda {
      Placement.statuses.map { |k, v| [k.humanize, v] }
                        .insert(1, %w[Disqualified disqualified])
    },
    include_blank: I18n.t("core.status"),
    placeholder: I18n.t("core.status")
  ) do |status|
    query =
      if status == "disqualified"
        where.not(placements: { status: %w[reserved qualified] })
      else
        where(placements: { status: })
      end
    query.joins(:placements).distinct
  end

  filter(
    :recruiter,
    :enum,
    select: lambda {
      Member
        .active
        .order("accounts.name")
        .pluck("accounts.name", :id)
        .unshift([I18n.t("core.no_assignee"), "nil"])
    },
    include_blank: I18n.t("core.recruiter"),
    placeholder: I18n.t("core.recruiter")
  ) do |recruiter_id|
    where(recruiter_id: recruiter_id == "nil" ? nil : recruiter_id)
  end

  filter(
    :include_blacklisted,
    :enum,
    select: [[I18n.t("candidates.include_blacklisted"), true]],
    default: ["false"],
    checkboxes: true
  ) do |val|
    where(blacklisted: false) if val.first == "false"
  end

  #
  # Columns
  #

  column(:avatar, html: true, order: false, header: "") do |model|
    link_to(
      tab_ats_candidate_path(model.id, :info)
    ) do
      picture_avatar_icon model.avatar, {}, class: "small-avatar-thumbnail"
    end
  end

  column(:name, html: true) do |model|
    link_to(
      model.full_name,
      tab_ats_candidate_path(
        model.id,
        :info
      )
    )
  end

  column(:company, order: false)

  column(
    :position_stage,
    header: "#{I18n.t('core.position')} - #{I18n.t('core.stage')}",
    preload: {
      placements: %i[position position_stage]
    },
    html: true
  ) do |model|
    candidates_grid_render_position_stage(model)
  end

  column(
    :recruiter,
    header: I18n.t("core.recruiter"),
    html: true,
    preload: { recruiter: :account }
  ) do |model|
    model.recruiter&.name
  end

  column(
    :added,
    order: "candidates.id DESC",
    order_desc: "candidates.id"
  ) do |model|
    # `added_date` should be `model.added_event.performed_at` but it creates N+1 query,
    # and if used with `includes(:events)` then too many events are preallocated as it is not
    # easily possible to include only a specific type of events.
    # `created_at` is a compromise between business logic and implementation.
    added_date = model.created_at
    format(added_date.to_fs(:datetime_full)) do |value|
      tag.span(data: { bs_toggle: "tooltip", placement: "top" }, title: value) do
        I18n.t("core.created_time", time: short_time_ago_in_words(added_date))
      end
    end
  end

  column(
    :last_activity,
    html: true,
    order: "candidates.last_activity_at DESC",
    order_desc: "candidates.last_activity_at"
  ) do |model|
    tag.span(data: { bs_toggle: "tooltip", placement: "top" },
             title: model.last_activity_at.to_fs(:datetime_full)) do
      I18n.t("core.last_activity", time: short_time_ago_in_words(model.last_activity_at))
    end
  end
end
