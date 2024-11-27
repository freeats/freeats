# frozen_string_literal: true

class Settings::Company::GeneralsController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :general }
  before_action :active_tab

  def show; end

  def active_tab
    @active_tab ||= :general
  end
end
