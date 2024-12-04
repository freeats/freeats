# frozen_string_literal: true

class Settings::Company::GeneralProfilesController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :general_profile }
  before_action :active_side_tab

  def show; end

  def update
    if current_tenant.update(name: params[:tenant][:name])
      render_turbo_stream(
        turbo_stream.update(
          :company_name,
          partial: "company_name",
          locals: { tenant: current_tenant }
        ), notice: t("settings.successfully_saved_notice")
      )
      return
    end

    render_error current_tenant.errors.full_messages
  end

  private

  def active_side_tab
    @active_side_tab ||= :general
  end
end
