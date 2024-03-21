# frozen_string_literal: true

class ATS::CandidatesController < ApplicationController
  include Dry::Monads[:result]
  # TODO: add authorization

  layout "ats/application"

  def index
    @candidates_grid = ATS::CandidatesGrid.new(
      helpers.add_default_sorting(
        params.fetch(:ats_candidates_grid, {})
        .merge(page: params[:page]),
        :added
      )
    ) do |scope|
      scope.page(params[:page])
    end

    @candidates_count = @candidates_grid.assets.unscope(:offset, :order, :limit).size
  end

  def show
    @candidate = Candidate.find(params[:id])

    render :show
  end

  def new
    partial_name = "new_candidate_modal"
    render(
      partial: partial_name,
      layout: "modal",
      locals: {
        modal_id: partial_name.dasherize,
        form_options: {
          url: ats_candidates_path,
          method: :post,
          data: {
            turbo_frame: "_top"
          }
        },
        hidden_fields: {
          position_id: params[:position_id]
        }
      }
    )
  end

  def create
    case Candidates::Add.new(params: candidate_params.to_h).call
    in Success(candidate)
      redirect_to tab_ats_candidate_path(candidate, :info),
                  notice: "Candidate was successfully created."
    in Failure[:candidate_invalid, candidate]
      redirect_to ats_candidates_path, alert: candidate.errors.full_messages
    end
  end

  def update
    @candidate = Candidate.find(params[:id])

    @candidate.attach_avatar(candidate_params[:avatar]) if candidate_params[:avatar].present?
    @candidate.destroy_avatar if candidate_params[:remove_avatar] == "1"

    @candidate.files.attach(candidate_params[:file]) if candidate_params[:file].present?
    if candidate_params[:file_id_to_remove].present?
      @candidate.files.find(candidate_params[:file_id_to_remove]).purge
    end

    redirect_to "/"
  end

  private

  def candidate_params
    params.require(:candidate).permit(:avatar, :remove_avatar, :full_name,
                                      :file, :file_id_to_remove)
  end
end
