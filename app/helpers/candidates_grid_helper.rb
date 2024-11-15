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
          case placement.status
          when "qualified"
            placement.position_stage.name
          when "reserved"
            safe_join(
              [render(IconComponent.new(:clock, size: :tiny)), placement.status.humanize],
              " "
            )
          when "disqualified"
            safe_join(
              [render(IconComponent.new(:ban, size: :tiny)), placement.disqualify_reason.title],
              " "
            )
          end
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
