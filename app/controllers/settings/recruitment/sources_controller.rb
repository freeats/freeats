# frozen_string_literal: true

class Settings::Recruitment::SourcesController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action { authorize! :sources }
  before_action :active_tab
  before_action :all_sources

  def show; end

  def update_all
    unless params[:modal_shown] == "true"
      sources_for_deleting =
        CandidateSource.all.filter { !_1.id.in?(new_sources_ids) }

      if sources_for_deleting.present?
        partial = "sources_delete_modal"
        render(
          partial:,
          layout: "modal",

          locals: {
            sources: sources_for_deleting,
            modal_id: partial.dasherize,
            form_options: {
              url: update_all_settings_recruitment_sources_path,
              method: :post,
              data: { turbo_frame: "_top" }

            },
            hidden_fields: params[:tenant].merge(modal_shown: true)
          }
        )
        return
      end
    end

    candidate_sources_params =
      if params[:modal_shown].nil?
        candidate_sources_params_without_modal
      else
        candidate_sources_params_from_modal
      end

    case CandidateSources::Change.new(
      actor_account: current_account,
      candidate_sources_params:
    ).call
    in Success()
      redirect_to settings_recruitment_sources_path,
                  notice: I18n.t("settings.recruitment.sources.update_all.successfully_updated")
    in Failure[:candidate_source_not_found, e]
      redirect_to settings_recruitment_sources_path,
                  alert: "Source not found: #{e.message}"
    in Failure[:deletion_failed, _e] | Failure[:invalid_sources, _e] # rubocop:disable Lint/UnderscorePrefixedVariableName
      render_error _e.message, status: :unprocessable_entity
    in Failure[:linkedin_source_cannot_be_changed]
      render_error "LinkedIn source cannot be changed", status: :unprocessable_entity
    end
  end

  private

  def active_tab
    @active_tab ||= :sources
  end

  def all_sources
    @all_sources ||=
      CandidateSource
      .all
      .sort_by(&:name)
      .sort_by { _1.name != "LinkedIn" ? 1 : 0 }
  end

  def new_sources_ids
    @new_sources_ids ||=
      params
      .require(:tenant)
      .permit(candidate_sources_attributes: %i[id name])[:candidate_sources_attributes]
      .to_h
      .map do |_, value|
        value["id"].to_i
      end
  end

  def candidate_sources_params_from_modal
    JSON
      .parse(params[:candidate_sources_attributes].gsub("=>", ":"))
      .filter { |_, value| !((value["id"] == "0" || value["id"].blank?) && value["name"].blank?) }
      .map do |_, value|
      { "id" => (value["id"].to_i if value["id"].present?),
        "name" => value["name"] }
    end
  end

  def candidate_sources_params_without_modal
    params
      .require(:tenant)
      .permit(candidate_sources_attributes: %i[id name])[:candidate_sources_attributes]
      .to_h
      .values
      .filter { |value| !(value["id"].blank? && value["name"].blank?) }
  end
end
