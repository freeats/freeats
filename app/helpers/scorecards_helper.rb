# frozen_string_literal: true

module ScorecardsHelper
  SCORE_STYLES = {
    irrelevant: [:mood_sad, "text-red"],
    relevant: [:mood_empty, "text-red-300"],
    good: [:mood_smile, "text-green-300"],
    perfect: [:mood_happy, "text-green"]
  }.freeze

  def score_icon(score, with_text: false)
    icon, color = SCORE_STYLES[score.to_sym]

    content_tag(:span, class: "d-flex align-items-center gap-2") do
      concat(render(IconComponent.new(icon, icon_type: :filled, class: color)))
      if with_text
        concat(
          t("candidates.advancement.#{score}_candidate")
        )
      end
    end
  end

  def visible_stages(placement)
    placement.position.stages_including_deleted.filter do |stage|
      stage.scorecard_template.present? &&
        (stage.list_index <= placement.position_stage.list_index && !stage.deleted) ||
        placement.scorecards.any? { _1.position_stage_id == stage.id }
    end
  end
end
