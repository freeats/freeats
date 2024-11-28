# frozen_string_literal: true

class Settings::Recruitment::SourcesController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :sources }
  before_action :active_tab

  def show; end

  private

  def active_tab
    @active_tab ||= :sources
  end
end
