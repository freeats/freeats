# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :email_templates }
  before_action :active_tab

  def index; end

  private

  def active_tab
    @active_tab ||= :email_templates
  end
end
