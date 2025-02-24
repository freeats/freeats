# frozen_string_literal: true

class API::V1::EmailTemplatesController < AuthorizedController
  before_action :authorize!

  def show
    candidate = Candidate.find(params[:candidate_id])
    template = EmailTemplate.find(params[:id])

    template_attributes = LiquidTemplate.extract_attributes_from(
      current_member:,
      candidate:
    )

    subject = template.subject
    message = template.message

    template_subject = ActionController::Base.helpers.sanitize(
      LiquidTemplate.new(subject).render(template_attributes)
    )
    template_message = ActionController::Base.helpers.sanitize(
      LiquidTemplate
        .new(ApplicationController.helpers.unescape_link_tags(message.body.to_html))
        .render(template_attributes)
    ).delete("\n")

    render json: { subject: template_subject, message: template_message }, status: :accepted
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end
end
