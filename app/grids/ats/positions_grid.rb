# frozen_string_literal: true

class ATS::PositionsGrid
  include Datagrid

  #
  # Scope
  #

  scope do
    Position.with_color_codes
  end

  attr_accessor(:current_account)

  #
  # Filters
  #

  filter(:name, :string, placeholder: I18n.t("core.name")) do |value|
    search_by_name(value)
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
    :status,
    :enum,
    select: -> { Position.statuses.transform_keys(&:humanize) },
    multiple: true,
    default: -> {
      %i[draft open on_hold]
    },
    placeholder: I18n.t("core.status")
  ) do |statuses|
    where("positions.status IN ( ? )", statuses)
  end

  filter(
    :recruiter,
    :enum,
    select: lambda {
      Member
        .joins(:account)
        .where(access_level: Position::RECRUITER_ACCESS_LEVEL)
        .or(
          Member.where(
            <<~SQL
              EXISTS(
                SELECT 1
                FROM positions
                WHERE positions.recruiter_id = members.id
                AND positions.status != 'closed'
              )
            SQL
          )
        )
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
    :collaborators,
    :enum,
    select: -> {
      Member
        .joins(:account)
        .where(access_level: Position::COLLABORATORS_ACCESS_LEVEL)
        .or(
          Member
            .where(
              <<~SQL
                EXISTS(
                  SELECT 1
                  FROM positions_collaborators
                  JOIN positions ON positions_collaborators.position_id = positions.id
                  WHERE positions_collaborators.collaborator_id = members.id
                  AND positions.status != 'closed'
                )
              SQL
            )
        )
        .order("accounts.name")
        .pluck("accounts.name", :id)
        .unshift([I18n.t("core.no_assignee"), "nil"])
    },
    include_blank: I18n.t("core.collaborator"),
    placeholder: I18n.t("core.collaborator")
  ) do |collaborator_id|
    collaborator_id = nil if collaborator_id == "nil"
    left_joins(:collaborators).where(positions_collaborators: { collaborator_id: })
  end

  filter(
    :hiring_managers,
    :enum,
    select: -> {
      Member
        .joins(:account)
        .where(access_level: Position::HIRING_MANAGERS_ACCESS_LEVEL)
        .or(
          Member
            .where(
              <<~SQL
                EXISTS(
                  SELECT 1
                  FROM positions_hiring_managers
                  JOIN positions ON positions_hiring_managers.position_id = positions.id
                  WHERE positions_hiring_managers.hiring_manager_id = members.id
                  AND positions.status != 'closed'
                )
              SQL
            )
        )
        .order("accounts.name")
        .pluck("accounts.name", :id)
        .unshift([I18n.t("core.no_assignee"), "nil"])
    },
    include_blank: I18n.t("core.hiring_manager"),
    placeholder: I18n.t("core.hiring_manager")
  ) do |hiring_manager_id|
    hiring_manager_id = nil if hiring_manager_id == "nil"
    left_joins(:hiring_managers).where(positions_hiring_managers: { hiring_manager_id: })
  end

  #
  # Columns
  #

  column(
    :status,
    order: false,
    header: "",
    html: true
  ) do |model|
    status_html = position_html_status_circle(model, tooltip_placement: "right")
    link_to status_html, tab_ats_position_path(model, :pipeline), class: "d-flex align-items-center"
  end

  column(
    :name,
    order: false,
    html: true
  ) do |model|
    link_to model.name, tab_ats_position_path(model, :info)
  end

  column(
    :city,
    header: I18n.t("core.city"),
    html: true,
    order: false
  ) do |model|
    model&.location&.short_name
  end

  column(
    :recruiter,
    html: true,
    preload: { recruiter: :account }
  ) do |model|
    model.recruiter&.account&.name
  end

  column(
    :collaborators,
    html: true,
    preload: { collaborators: :account }
  ) do |model|
    model.collaborators.map do |collaborator|
      collaborator.account.name
    end.join(", ")
  end

  column(
    :hiring_managers,
    html: true,
    preload: { hiring_managers: :account }
  ) do |model|
    model.hiring_managers.map do |hiring_manager|
      hiring_manager.account.name
    end.join(", ")
  end
end
