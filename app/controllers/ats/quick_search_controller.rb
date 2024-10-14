# frozen_string_literal: true

class ATS::QuickSearchController < AuthorizedController
  COUNT_LIMIT = 100

  before_action { authorize! :quick_search }

  def index
    case params[:searching_for]
    when "candidate"
      search_candidates
    when "position"
      search_positions
    end

    render partial: "options",
           locals: { dataset: @dataset, partials: @partials,
                     see_more_partial: @see_more_partial }
  end

  private

  def search_candidates
    limit = params[:limit]&.to_i || 3

    @dataset =
      Candidate
      .search_by_names_or_emails(params[:q])
      .order(last_activity_at: :desc)
      .limit(limit)

    @partials = @dataset.map do |element|
      render_to_string(
        partial: "candidate_element",
        locals: { candidate: element }
      )
    end
    dataset_count = Candidate.search_by_names_or_emails(params[:q]).limit(COUNT_LIMIT).size
    return unless (dataset_count - limit).positive?

    dataset_count = "99+" if dataset_count == COUNT_LIMIT
    @see_more_partial = render_to_string(
      "see_more",
      formats: %i[html],
      layout: nil,
      locals: {
        link: ats_candidates_path(
          ats_candidates_grid: { candidate: params[:q], order: :last_activity }
        ),
        count: dataset_count,
        collection_name: "candidate"
      }
    )
  end

  def search_positions
    limit = 3

    @dataset =
      Position
      .with_color_codes
      .search_by_name(params[:q])
      .order(:color_code)
      .limit(limit)

    @partials = @dataset.map do |element|
      render_to_string(
        "position_element",
        formats: %i[html],
        layout: nil,
        locals: { position: element }
      )
    end
    dataset_count = Position.search_by_name(params[:q]).limit(COUNT_LIMIT).size
    return unless (dataset_count - limit).positive?

    positions_grid_params = { status: Position.statuses.keys, name: params[:q] }
    see_more_link = ats_positions_path(ats_positions_grid: positions_grid_params)
    dataset_count = "99+" if dataset_count == COUNT_LIMIT
    @see_more_partial = render_to_string(
      "see_more",
      formats: %i[html],
      layout: nil,
      locals: {
        link: see_more_link,
        count: dataset_count,
        collection_name: "position"
      }
    )
  end
end
