# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesController < AuthorizedController
  layout "ats/application"

  before_action { @nav_item = :settings }
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
    email_template = EmailTemplate.new(template_params)

    save_email_template_and_send_response(email_template)
  end

  def update
    email_template = EmailTemplate.find(params[:id])
    email_template.assign_attributes(template_params)

    save_email_template_and_send_response(email_template)
  end

  private

  def active_tab
    @active_tab ||= :email_templates
  end

  def template_params
    params.require(:email_template).permit(:subject, :name, :message)
  end

  def save_email_template_and_send_response(email_template)
    if email_template.save
      render_turbo_stream(
        turbo_stream.replace(
          :settings_form,
          partial: "form",
          locals: { email_template: }
        ),
        notice: t("settings.successfully_saved_notice")
      )
      return
    end

    render_error email_template.errors.full_messages
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?("index_email_templates_on_tenant_id_and_name")

    render_turbo_stream(
      [],
      error: t("settings.recruitment.email_templates.name_already_taken_alert"),
      status: :unprocessable_entity
    )
  end
end
