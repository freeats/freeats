# frozen_string_literal: true

class ATS::MembersController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action { @nav_item = :team }
  before_action :authorize!

  def index
    @team_grid = ATS::TeamGrid.new(current_member:)
  end

  def deactivate
    account = Account.find_by(id: params[:id])

    unless account
      render_error I18n.t("user_accounts.not_found"), status: :unprocessable_entity
      return
    end

    if account.member.inactive?
      render_error I18n.t("user_accounts.already_has_inactive_level", name: account.name),
                   status: :unprocessable_entity
      return
    end

    if account == current_account
      render_error I18n.t("user_accounts.deactivate_self_error"), status: :unprocessable_entity
      return
    end

    if account.member.deactivate
      redirect_to ats_team_path,
                  notice: I18n.t("user_accounts.successfully_deactivated", name: account.name)
    else
      render_error account.member.errors.full_messages, status: :unprocessable_entity
    end
  end

  def invite_modal
    partial = "invite_modal"
    render(
      partial:,
      layout: "modal",
      locals: {
        modal_id: partial.dasherize,
        form_options: {
          url: invite_ats_members_path,
          method: :post,
          data: { turbo_frame: "_top" }
        }
      }
    )
  end

  def invite
    case Members::Invite.new(
      actor_account: current_account,
      email: params[:email]
    ).call
    in Success[access_token]
      redirect_to ats_team_path,
                  notice: I18n.t(
                    "user_accounts.sussessfully_sent_invitation",
                    email: access_token.sent_to
                  )
    in Failure[:account_already_exists]
      render_error I18n.t("user_accounts.already_exists", email: params[:email]),
                   status: :unprocessable_entity
    in Failure[:invalid_email]
      render_error I18n.t("user_accounts.invalid_email", email: params[:email]),
                   status: :unprocessable_entity
    end
  end

  def reactivate
    account = Account.find_by(id: params[:id])

    unless account
      render_error I18n.t("user_accounts.not_found"), status: :unprocessable_entity
      return
    end

    if account.member.active?
      render_error I18n.t(
        "user_accounts.already_has_access_level",
        name: account.name,
        access_level: account.member.access_level
      ), status: :unprocessable_entity
      return
    end

    if account.member.reactivate
      redirect_to ats_team_path,
                  notice: I18n.t("user_accounts.successfully_reactivated", name: account.name)
    else
      render_error account.member.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update_level_access
    account = Account.find_by(id: params[:id])

    new_access_level = params[:access_level]

    unless new_access_level.in?(%w[admin member])
      render_error I18n.t("user_accounts.invalid_access_level", new_access_level:),
                   status: :unprocessable_entity
      return
    end

    if account.member.access_level == new_access_level
      render_error I18n.t(
        "user_accounts.already_has_access_level",
        name: account.name,
        access_level: new_access_level
      ), status: :unprocessable_entity
      return
    end

    if account.member.update(access_level: new_access_level)
      redirect_to ats_team_path,
                  notice: I18n.t(
                    "user_accounts.successfully_updated",
                    name: account.name,
                    new_access_level:
                  )
    else
      render_error account.member.errors.full_messages, status: :unprocessable_entity
    end
  end
end
