# frozen_string_literal: true

class ATS::ComposeController < AuthorizedController
  include SchemaHelper
  before_action { authorize! :compose }

  def new
    candidate = Candidate.find(params[:candidate_id])
    email_addresses = candidate.all_emails

    render_turbo_stream(
      turbo_stream.replace(
        "turbo_email_compose_form",
        partial: "ats/email_messages/email_compose_form",
        locals: { email_addresses: }
      )
    )
  end

  def create
    email_message_params = compose_email_message_params
    validation = EmailMessageSchema.new.call(email_message_params.compact)
    if validation.errors.present?
      render_error schema_errors_to_string(validation.errors), status: :unprocessable_entity
      return
    end

    EmailMessageMailer.with(email_message_params).send_email.deliver_now
  end

  private

  def compose_email_message_params
    result = { from: "notifications@freeats.com", reply_to: current_member.email_address }

    result[:to] = params.dig(:email_message, :to).map(&:strip)
    result[:cc] = (params.dig(:email_message, :cc) || []).map(&:strip)
    result[:bcc] = (params.dig(:email_message, :bcc) || []).map(&:strip)
    result[:subject] = params.dig(:email_message, :subject)
    result[:html_body] = params.dig(:email_message, :html_body)

    result
  end
end
