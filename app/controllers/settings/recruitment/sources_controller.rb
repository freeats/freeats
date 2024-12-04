# frozen_string_literal: true

class Settings::Recruitment::SourcesController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action { @nav_item = :settings }
  before_action { authorize! :sources }
  before_action :active_tab
  before_action :all_sources, only: :index

  def index; end

  def update_all
    unless params[:modal_shown] == "true"
      sources_for_deleting =
        CandidateSource.all.filter { !_1.id.in?(new_sources_ids) }

      if sources_for_deleting.present?
        hidden_fields = { modal_shown: true }
        candidate_sources_params.each_with_index do |value, index|
          hidden_fields["tenant[candidate_sources_attributes][#{index}][id]"] = value[:id]
          hidden_fields["tenant[candidate_sources_attributes][#{index}][name]"] = value[:name]
        end

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
            hidden_fields:
          }
        )
        return
      end
    end

    case Settings::Recruitment::Sources::Change.new(
      actor_account: current_account,
      candidate_sources_params:
    ).call
    in Success()
      render_turbo_stream(
        turbo_stream.replace(
          :settings_form,
          partial: "sources_edit",
          locals: { tenant: current_tenant, all_sources: }
        ), notice: t("settings.successfully_saved_notice")
      )
    in Failure[:candidate_source_not_found, _e] | Failure[:deletion_failed, _e] | # rubocop:disable Lint/UnderscorePrefixedVariableName
       Failure[:invalid_sources, _e]
      render_error _e.message, status: :unprocessable_entity
    in Failure[:linkedin_source_cannot_be_changed]
      render_error t(".linkedin_error"),
                   status: :unprocessable_entity
    end
  end

  private

  def active_tab
    @active_tab ||= :sources
  end

  def all_sources
    @all_sources =
      CandidateSource
      .all
      .sort_by(&:name)
      .sort_by { _1.name != "LinkedIn" ? 1 : 0 }
  end

  def new_sources_ids
    @new_sources_ids ||= candidate_sources_params.map { _1[:id].to_i }
  end

  def candidate_sources_params
    @candidate_sources_params ||=
      params
      .require(:tenant)
      .permit(candidate_sources_attributes: %i[id name])[:candidate_sources_attributes]
      .to_h
      .values
      .filter_map do |value|
        value.symbolize_keys if value["id"].present? || value["name"].present?
      end
  end
end
