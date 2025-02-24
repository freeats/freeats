# frozen_string_literal: true

class Settings::Recruitment::DisqualifyReasonsController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action { @nav_item = :settings }
  before_action { authorize! :disqualify_reasons }
  before_action :active_tab

  def index
    @disqualify_reasons = DisqualifyReason.not_deleted
  end

  def bulk_update
    unless params[:modal_shown] == "true"
      disqualify_reasons_for_deleting =
        DisqualifyReason.not_deleted.filter { !_1.id.in?(new_disqualify_reasons_ids) }

      if disqualify_reasons_for_deleting.present?
        hidden_fields = { modal_shown: true }
        disqualify_reasons_params.each_with_index do |value, index|
          hidden_fields["tenant[disqualify_reasons_attributes][#{index}][id]"] = value[:id]
          hidden_fields["tenant[disqualify_reasons_attributes][#{index}][title]"] = value[:title]
          hidden_fields["tenant[disqualify_reasons_attributes][#{index}][description]"] =
            value[:description]
        end

        partial = "delete_modal"
        render(
          partial:,
          layout: "modal",
          locals: {
            disqualify_reasons: disqualify_reasons_for_deleting,
            modal_id: partial.dasherize,
            form_options: {
              url: bulk_update_settings_recruitment_disqualify_reasons_path,
              method: :post,
              data: { turbo_frame: "_top" }

            },
            hidden_fields:
          }
        )
        return
      end
    end

    case Settings::Recruitment::DisqualifyReasons::BulkUpdate.new(
      disqualify_reasons_params:
    ).call
    in Success()
      disqualify_reasons = DisqualifyReason.not_deleted
      render_turbo_stream(
        turbo_stream.replace(
          :settings_form,
          partial: "edit",
          locals: { tenant: current_tenant, disqualify_reasons: }
        ), notice: t("settings.successfully_saved_notice")
      )
    in Failure[:deletion_failed, _e] | # rubocop:disable Lint/UnderscorePrefixedVariableName
       Failure[:invalid_disqualify_reasons, _e]
      render_error _e.message, status: :unprocessable_entity
    in Failure[:disqualify_reason_not_found, _e]
      render_error _e, status: :unprocessable_entity
    in Failure[:disqualify_reason_cannot_be_changed]
      render_error t(".disqualify_reason_error"),
                   status: :unprocessable_entity
    end
  end

  def new_disqualify_reasons_ids
    @new_disqualify_reasons_ids ||= disqualify_reasons_params.map { _1[:id].to_i }
  end

  def disqualify_reasons_params
    @disqualify_reasons_params ||=
      params
      .require(:tenant)
      .permit(disqualify_reasons_attributes: %i[id title
                                                description])[:disqualify_reasons_attributes]
      .to_h
      .values
      .filter_map do |value|
        value.symbolize_keys if value["id"].present? || value["title"].present?
      end
  end

  private

  def active_tab
    @active_tab ||= :disqualify_reasons
  end
end
