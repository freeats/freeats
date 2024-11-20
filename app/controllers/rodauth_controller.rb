# frozen_string_literal: true

class RodauthController < ApplicationController
  layout "ats/application"
  # used by Rodauth for rendering views, CSRF protection, and running any
  # registered action callbacks and rescue_from handlers

  before_action :validate_and_set_tokens, only: %i[invite accept_invite]
  before_action :set_gon_variables

  def register
    render
  end

  def verify_email
    render
  end

  # Rodauth did not provide the functionality to create an account via invitation,
  # and we must implement it ourselves.
  def invite
    render
  end

  # Rodauth did not provide the functionality to create an account via invitation,
  # and we must implement it ourselves.
  def accept_invite
    if params[rodauth.password_param] != params[rodauth.password_confirm_param]
      rodauth.set_field_error(rodauth.password_param, t("rodauth.passwords_do_not_match_message"))
      flash.now[:alert] = t("rodauth.create_account_error_flash")
      return render :invite, status: :unprocessable_entity
    end

    email_address = @access_token.sent_to
    ActiveRecord::Base.transaction do
      RodauthApp.rodauth.create_account(
        login: @access_token.sent_to, password: params[rodauth.password_param],
        params: { "full_name" => params[:full_name], "tenant_id" => @access_token.tenant_id }
      )
      @access_tokens_sent_to_same_address.destroy_all
    end

    # The below lines set the account auto-login.
    rodauth.account_from_login(email_address)
    rodauth.autologin_session("create_account")

    redirect_to root_path, notice: t("rodauth.success_invitation_notice_flash")
  rescue Rodauth::InternalRequestError => e
    e.field_errors.each do |field, error|
      rodauth.set_field_error(field, error)
    end
    flash.now[:alert] = t("rodauth.create_account_error_flash")
    render :invite, status: :unprocessable_entity
  end

  private

  def validate_and_set_tokens
    return render404 if params[:token].blank?

    @invite_token = params[:token]
    @access_token = AccessToken.find_by(hashed_token: Digest::SHA256.digest(@invite_token))
    if @access_token.present?
      @access_tokens_sent_to_same_address = AccessToken.where(sent_to: @access_token.sent_to)
    end

    if current_account
      @access_tokens_sent_to_same_address&.destroy_all
      redirect_to root_path, warning: t("rodauth.invitation_already_have_account_error_flash")
    elsif @access_token.blank?
      redirect_to rodauth.login_path, alert: t("rodauth.no_invitation_error_flash")
    elsif !@access_token.member_invitation?
      render404
    elsif Account.find_by(email: @access_token.sent_to).present?
      @access_tokens_sent_to_same_address.destroy_all
      redirect_to rodauth.login_path,
                  warning: t("rodauth.invitation_already_registered_error_flash")
    elsif @access_token.expired?
      redirect_to rodauth.login_path, alert: t("rodauth.expired_invitation_error_flash")
    end
  end
end
