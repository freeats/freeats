# frozen_string_literal: true

class Settings::Recruitment::SourcesController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :sources }
  before_action :active_tab

  def show; end

  def update_modal
    # Need check linkedin source
    old_sources = CandidateSource.all

    new_sources_ids =
      params
      .require(:tenant)
      .permit(candidate_sources_attributes: %i[id name])[:candidate_sources_attributes]
      .to_h.map do |_, value|
        value["id"].to_i
      end

    sources_for_deleting = old_sources.filter { !_1.id.in?(new_sources_ids) }
    partial = "sources_delete_modal"
    render(
      partial:,
      layout: "modal",

      locals: {
        sources: sources_for_deleting,
        modal_id: partial.dasherize,
        form_options: {
          url: update_with_modal_settings_recruitment_sources_path,
          method: :post,
          data: { turbo_frame: "_top" }
        },
        hidden_fields: params[:tenant]
      }
    )
  end

  def update_with_modal
    # Need check linkedin source
    old_sources = CandidateSource.all

    clean_params =
      JSON
      .parse(params[:candidate_sources_attributes].gsub("=>", ":"))
      .filter { |_, value| !(value["id"] == "0" && value["name"].blank?) }
      .map { |_, value| [(value["id"].to_i if value["id"] != "0"), value["name"]] }

    new_sources = clean_params.map do |source|
      if source[0].nil?
        CandidateSource.create(name: source[1])
      else
        CandidateSource.find(source[0]).update(name: source[1])
      end
    end

    sources_for_deleting = old_sources.filter do |source|
      new_sources.ids.exclude?(source.id)
    end

    destroy_without_dependecies(sources_for_deleting)
    redirect_to settings_recruitment_sources_path
  end

  private

  def active_tab
    @active_tab ||= :sources
  end

  def destroy_without_dependecies(sources_for_deleting)
    Candidate.where(candidate_source_id: sources_for_deleting.ids).update(candidate_source_id: nil)
    sources_for_deleting.destroy_all
  end
end
