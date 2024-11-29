# frozen_string_literal: true

class ATS::ComposeController < AuthorizedController
  include SchemaHelper
  before_action { authorize! :compose }

  FROM_ADDRESS = "notifications@freeats.com"

  def new
    candidate = Candidate.find(params[:candidate_id])
    candidate_email_addresses = candidate.all_emails
    members_email_addresses = Member.email_addresses(except: current_member)

    render_turbo_stream(
      turbo_stream.replace(
        "turbo_email_compose_form",
        partial: "ats/email_messages/email_compose_form",
        locals: { candidate_email_addresses:, members_email_addresses: }
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

    email_addresses = email_message_params[:to].join(", ")
    result = EmailMessageMailer.with(email_message_params).send_email.deliver_now!

    if (result.is_a?(Net::SMTP::Response) && result.status == "250") ||
       (result.is_a?(Mail::Message) && !Rails.env.production?)
      render_turbo_stream(
        [],
        notice: t("candidates.email_compose.email_sent_success_notice", email_addresses:)
      )
    else
      render_turbo_stream(
        [],
        error: t("candidates.email_compose.email_sent_fail_alert", email_addresses:),
        status: :unprocessable_entity
      )
    end
  end

  private

  def compose_email_message_params
    result = { from: FROM_ADDRESS, reply_to: current_member.email_address }

    result[:to] = params.dig(:email_message, :to).map(&:strip)
    result[:cc] = (params.dig(:email_message, :cc) || []).map(&:strip)
    result[:bcc] = (params.dig(:email_message, :bcc) || []).map(&:strip)
    result[:subject] = params.dig(:email_message, :subject)
    result[:html_body] = params.dig(:email_message, :html_body)

    result
  end
end
