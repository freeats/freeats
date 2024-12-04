# frozen_string_literal: true

class Settings::Recruitment::DisqualifyReasonsController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :disqualify_reasons }
  before_action :active_tab

  def show; end

  private

  def active_tab
    @active_tab ||= :disqualify_reasons
  end
end
