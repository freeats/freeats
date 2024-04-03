# frozen_string_literal: true

class ATS::DashboardCandidatesGrid
  include Datagrid

  attr_accessor :current_member_id

  #
  # Scope
  #

  scope do
    Candidate.with_attached_avatar
  end

  #
  # Columns
  #

  column(:avatar, html: true, header: "", order: false) do |model|
    link_to(
      tab_ats_candidate_path(model.id, :info)
    ) do
      picture_avatar_icon model.avatar, {}, class: "small-avatar-thumbnail"
    end
  end

  column(:name, html: true, order: false) do |model|
    link_to(
      model.full_name,
      tab_ats_candidate_path(model.id, :info)
    )
  end

  column(
    :position_stage,
    header: "Position - Stage",
    preload: {
      placements: %i[position position_stage]
    },
    html: true
  ) do |model|
    candidates_grid_render_position_stage(model)
  end

  column(
    :recruiter,
    header: "Recruiter",
    html: true,
    preload: { recruiter: :account }
  ) do |model|
    model.recruiter.name
  end

  column(:added, html: true) do |model|
    tag.span(data: { bs_toggle: "tooltip", placement: "top" },
             title: model.created_at.to_fs(:datetime_full)) do
      "#{short_time_ago_in_words(model.created_at)} ago"
    end
  end

  column(:last_activity, html: true) do |model|
    tag.span(data: { bs_toggle: "tooltip", placement: "top" },
             title: model.last_activity_at.to_fs(:datetime_full)) do
      "#{short_time_ago_in_words(model.last_activity_at)} ago"
    end
  end
end
