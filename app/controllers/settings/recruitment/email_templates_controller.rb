# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :email_templates }
  before_action :active_tab

  def index
    @email_templates_grid = Settings::Recruitment::EmailTemplatesGrid.new(
      helpers.add_default_sorting(params[:settings_recruitment_email_templates_grid],
                                  :updated,
                                  :asc)
    ) do |scope|
      scope.page(params[:page])
    end
  end

  def show
    @email_template = EmailTemplate.find(params[:id])
  end

  private

  def active_tab
    @active_tab ||= :email_templates
  end
end
