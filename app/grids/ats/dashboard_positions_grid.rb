# frozen_string_literal: true

class ATS::DashboardPositionsGrid
  include Datagrid

  #
  # Scope
  #

  scope do
    Position
      .select("distinct on (id) positions.*")
      .joins(
        <<~SQL
          LEFT JOIN placements
          ON placements.position_id = positions.id AND placements.status = 'qualified'
          LEFT JOIN candidates
          ON placements.candidate_id = candidates.id AND candidates.merged_to IS NULL
        SQL
      )
      .where(status: %i[draft open on_hold])
  end

  #
  # Columns
  #

  column(
    :status,
    header: "",
    order: false,
    preload: :added_event,
    html: true
  ) do |model|
    status_html = position_html_status_circle(model, tooltip_placement: "right")
    link_to status_html, tab_ats_position_path(model, :pipeline)
  end

  column(
    :name,
    html: true,
    order: false
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
    model.recruiter&.name
  end

  column(
    :collaborators,
    html: true,
    preload: { collaborators: :account }
  ) do |model|
    model.collaborators.map(&:name).join(", ")
  end

  column(
    :hiring_managers,
    html: true,
    preload: { hiring_managers: :account }
  ) do |model|
    model.hiring_managers.map(&:name).join(", ")
  end
end
