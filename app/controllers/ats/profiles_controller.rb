# frozen_string_literal: true

class ATS::ProfilesController < ApplicationController
  layout "ats/application"

  include Dry::Monads[:result]

  before_action { authorize! :profile }

  def show
    @email_address = {
      address: current_member.email_address,
      token_present: current_member.email_service_linked?
    }
    @link_gmail_uri = Gmail::Auth.authorization_uri(redirect_uri: link_gmail_ats_profile_url)
  end

  def link_gmail
    rs = EmailSynchronization::RetrieveGmailTokens.new(
      current_member:,
      code: params[:code],
      redirect_uri: link_gmail_ats_profile_url
    ).call

    case rs
    in Failure[:failed_to_fetch_tokens, _e] |
       Failure[:failed_to_retrieve_email_address, _e] |
       Failure[:new_tokens_are_not_saved, _e]
      Log.tagged("link_gmail") { _1.external_log(_e) }
      redirect_to ats_profile_path, alert: "Something went wrong, please contact support."
    in Failure[:emails_not_match, linked_email]
      redirect_to ats_profile_path,
                  alert: "The linked email #{linked_email} does not match the current email."
    in Success()
      # TODO: synchronize emails for this address.
      # if current_member.sync_emails
      #   ReceiveEmailMessageUpdatesJob.perform_later(from_member_id: current_member.id)
      # end
      redirect_to ats_profile_path, notice: "Gmail successfully linked."
    end
  end
end
