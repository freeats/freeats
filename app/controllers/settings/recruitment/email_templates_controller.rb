# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :email_templates }
  before_action :active_side_tab

  def index
    @email_templates_grid = Settings::Recruitment::EmailTemplatesGrid.new do |scope|
      scope.page(params[:page])
    end
  end

  def show
    @email_template = EmailTemplate.find(params[:id])
  end

  def new
    @email_template = EmailTemplate.new
  end

  private

  def active_side_tab
    @active_side_tab ||= :email_templates
  end
end
