# frozen_string_literal: true

module CandidatesGridHelper
  def candidates_grid_render_position_stage(model)
    placements = candidates_grid_sort_placements(model.placements).map do |placement|
      safe_join(
        [
          (if allowed_to?(:show?, placement.position, with: ATS::PositionPolicy)
             link_to(
               placement.position.name,
               tab_ats_position_path(placement.position, :pipeline)
             )
           else
             placement.position.name
           end),
          sanitize(
            case placement.status
            when "qualified"
              placement.position_stage.name
            when "reserved"
              "<i class='far fa-clock'></i>&nbsp;#{placement.status.humanize}"
            else
              "<i class='fas fa-ban'></i>&nbsp;#{placement.status.humanize}"
            end
          )
        ],
        " - "
      )
    end

    safe_join(placements, "<br />".html_safe)
  end

  def candidates_grid_sort_placements(placements)
    all_placements = placements.sort_by(&:created_at).reverse
    qualified_placements = all_placements.filter { |p| p.status == "qualified" }
    unqualified_placements = all_placements - qualified_placements

    qualified_placements + unqualified_placements
  end
end
