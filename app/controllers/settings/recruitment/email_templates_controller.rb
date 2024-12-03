# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesController < AuthorizedController
  layout "ats/application"

  before_action { authorize! :email_templates }
  before_action :active_tab

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

  def create
  end

  def update
    @email_template = EmailTemplate.find(params[:id])

    if @email_template.update(template_params)
      render_turbo_stream(
        turbo_stream.replace(
          :settings_form,
          partial: "form",
          locals: { email_template: @email_template }
        ),
        notice: t("settings.successfully_saved_notice")
      )
      return
    end

    render_error @email_template.errors.full_messages
  end

  private

  def active_tab
    @active_tab ||= :email_templates
  end

  def template_params
    params.require(:email_template).permit(:subject, :name, :body)
  end
end
