# frozen_string_literal: true

class ATS::ComposeController < AuthorizedController
  before_action { authorize! :compose }

  def new
    # reply_to_message = nil

    # form_presets =
    #   if params[:message_id].present?
    #     reply_to_message = EmailMessage.find(params[:message_id])
    #     reply_to_message.compose_form_presets_on_reply(current_member:)
    #   else
    #     { default_to_address: params[:default_to_address] }
    #   end

    # render_turbo_stream(
    #   turbo_stream.replace(
    #     "turbo_form",
    #     partial: "hub/email_messages/form",
    #     locals: {
    #       **form_presets,
    #       person_ids: params[:person_ids],
    #       reply_to_message:,
    #       templates: current_member.shared_and_personal_email_templates,
    #       email_addresses: Member.email_addresses(except: current_member),
    #       controller_name: params[:controller_name]
    #     }
    #   )
    # )
  end
end
