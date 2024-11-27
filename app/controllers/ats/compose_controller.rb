# frozen_string_literal: true

class ATS::ComposeController < AuthorizedController
  before_action { authorize! :compose }

  def new
    render_turbo_stream(
      turbo_stream.replace(
        "turbo_email_compose_form",
        partial: "ats/email_messages/email_compose_form",
        locals: {
          default_to_address: params[:default_to_address],
          email_addresses: Member.email_addresses(except: current_member)
        }
      )
    )
  end
end
