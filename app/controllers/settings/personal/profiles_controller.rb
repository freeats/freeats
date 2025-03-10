# frozen_string_literal: true

class Settings::Personal::ProfilesController < AuthorizedController
  layout "ats/application"

  include Dry::Monads[:result]

  before_action { @nav_item = :settings }
  before_action { authorize! :profile }
  before_action :set_partial_variables, only: :show
  before_action :set_gon_variables, only: :show
  before_action :active_tab

  def show; end

  def update_account
    if current_account.update(params.require(:account).permit(:name))
      render_turbo_stream(
        turbo_stream.update(
          :account_info,
          partial: "account_info",
          locals: { account: current_account }
        ),
        notice: t("settings.successfully_saved_notice")
      )
      return
    end

    render_error current_account.errors.full_messages
  end

  def update_avatar
    if current_account.update(params.require(:account).permit(:avatar))
      render_turbo_stream(
        turbo_stream.update(
          :account_avatar,
          partial: "account_avatar",
          locals: { account: current_account }
        ),
        notice: t("settings.person.profile.update_avatar.successfully_updated")
      )
      return
    end

    render_error current_account.errors.full_messages
  end

  def remove_avatar
    current_account.avatar.purge
    current_account.save!
    render_turbo_stream(
      turbo_stream.update(
        :account_avatar,
        partial: "account_avatar",
        locals: { account: current_account }
      ),
      notice: t("settings.person.profile.remove_avatar.successfully_removed")
    )
  rescue StandardError => e
    render_error e.message
  end

  def link_gmail
    rs = EmailSynchronization::RetrieveGmailTokens.new(
      current_member:,
      code: params[:code],
      redirect_uri: link_gmail_settings_personal_profile_url
    ).call

    case rs
    in Failure[:failed_to_fetch_tokens, _e] | # rubocop:disable Lint/UnderscorePrefixedVariableName
       Failure[:failed_to_retrieve_email_address, _e] |
       Failure[:new_tokens_are_not_saved, _e]
      Log.tagged("link_gmail") { _1.external_log(_e) }
      redirect_to settings_personal_profile_path,
                  alert: "Something went wrong, please contact support."
    in Failure[:emails_not_match, linked_email]
      redirect_to settings_personal_profile_path,
                  alert: "The linked email #{linked_email} does not match the current email."
    in Success()
      # ReceiveEmailMessageUpdatesForMemberJob.perform_later(current_member.id)
      redirect_to settings_personal_profile_path, notice: "Gmail successfully linked."
    end
  end

  private

  def set_partial_variables
    return unless allowed_to?(:link_gmail?, :profile)

    @link_gmail_uri =
      Gmail::Auth.authorization_uri(redirect_uri: link_gmail_settings_personal_profile_url)
  end

  def active_tab
    @active_tab ||= :profile
  end
end
