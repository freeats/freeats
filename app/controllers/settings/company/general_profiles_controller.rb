# frozen_string_literal: true

class Settings::Company::GeneralProfilesController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :general_profile }
  before_action :active_tab

  def show; end

  private

  def active_tab
    @active_tab ||= :general
  end
end
