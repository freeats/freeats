# frozen_string_literal: true

module CandidatesHelper
  def candidates_compose_source_option_for_select(candidate_source, selected: true)
    {
      text: candidate_source.name,
      value: candidate_source.name,
      selected:
    }
  end
end
