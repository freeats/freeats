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

  filter(:name, :string, placeholder: "Name") do |value|
    search_by_name(value)
  end

  filter(
    :status,
    :enum,
    select: -> { Position.statuses.transform_keys(&:humanize) },
    multiple: true,
    default: -> {
      Position.statuses.keys
    },
    placeholder: "Status"
  ) do |statuses|
    where("positions.status IN ( ? )", statuses)
  end

  filter(
    :recruiter,
    :enum,
    select: lambda {
      Member
        .joins(:account)
        .active
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
    },
    include_blank: "Recruiter",
    placeholder: "Recruiter"
  )

  filter(
    :collaborators,
    :enum,
    select: -> { Member.joins(:account).active.order("accounts.name").pluck("accounts.name", :id) },
    include_blank: "Collaborator",
    placeholder: "Collaborator"
  ) do |collaborator_id|
    joins(:collaborators).where(positions_collaborators: { collaborator_id: })
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
    if current_member.employee?
      link_to status_html, tab_ats_position_path(model, :pipeline)
    else
      status_html
    end
  end

  column(
    :name,
    order: false,
    html: true
  ) do |model|
    link_to model.name, tab_ats_position_path(model, :info)
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
end
