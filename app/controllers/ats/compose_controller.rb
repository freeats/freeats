# frozen_string_literal: true

class ATS::ComposeController < AuthorizedController
  include SchemaHelper
  before_action { authorize! :compose }

  FROM_ADDRESS = ENV.fetch("NOTIFICATION_ADDRESS", nil)

  def new
    candidate = Candidate.find(params[:candidate_id])
    candidate_email_addresses = candidate.all_emails
    members_email_addresses = Member.email_addresses(except: current_member).sort

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
      Log.tagged("ATS::ComposeController#create") do |logger|
        logger.external_log("email message was not sent", email_message_params:,
                                                          result: result.inspect)
      end
      render_turbo_stream(
        [],
        error: t("candidates.email_compose.email_sent_fail_alert", email_addresses:),
        status: :unprocessable_entity
      )
    end
  end

  private

  def compose_email_message_params
    email_message_params =
      params
      .require(:email_message)
      .permit(:subject, :html_body, to: [], cc: [], bcc: [])
      .to_h
      .symbolize_keys

    result = { from: FROM_ADDRESS, reply_to: current_member.email_address }

    result[:to] = email_message_params[:to].map(&:strip)
    result[:cc] = (email_message_params[:cc] || []).map(&:strip)
    result[:bcc] = (email_message_params[:bcc] || []).map(&:strip)
    result[:subject] = email_message_params[:subject]
    result[:html_body] = email_message_params[:html_body]

    result
  end
end
