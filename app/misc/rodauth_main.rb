# frozen_string_literal: true

require "sequel/core"

# https://rodauth.jeremyevans.net/rdoc/files/doc/create_account_rdoc.html
# https://rodauth.jeremyevans.net/rdoc/files/doc/guides/registration_field_rdoc.html
module CreateAccount
  extend ActiveSupport::Concern
  MAILER_ENABLED = ENV.fetch("EMAIL_NOTIFICATIONS", "disabled") == "enabled"

  included do
    configure do
      enable :create_account
      create_account_route :register
      create_account_autologin? do
        Account.find_by(id: account[:id]).verified?
      end
      create_account_redirect do
        if Account.find_by(id: account[:id]).verified?
          login_redirect
        else
          verify_account_resend_path(login_param => param(login_param))
        end
      end

      # Validate the presence of custom fields which are required
      # to create a tenant, member and account.
      before_create_account do
        unless (name = param_or_nil("full_name"))
          throw_error_status(422, "full_name", I18n.t("rodauth.required_field_error"))
        end
        unless internal_request?
          if param("company_name").empty?
            throw_error_status(422, "company_name", I18n.t("rodauth.required_field_error"))
          end

          verify_recaptcha
        end

        account[:name] = name
      end

      # The `internal_request` is used for creating a member for the existing tenant
      # when we invite a new member.
      # Otherwise we register a new tenant and a new member.
      after_create_account do
        if internal_request?
          tenant_id = param("tenant_id")
          account = Account.find(account_id)
          account.update!(tenant_id:)
          account.verified!
          Member.create!(account_id:, tenant_id:, access_level: :member)
        else
          tenant = Tenant.create!(name: param("company_name"))
          account = Account.find(account_id)
          account.update!(tenant_id: tenant.id)
          Member.create!(account_id:, tenant:, access_level: :admin)
          CandidateSource.create!(tenant:, name: "LinkedIn")
          # If mailer is not enabled, it's impossible to verify account via email.
          account.verified! unless MAILER_ENABLED
        end
      end

      create_account_view do
        if field_error("recaptcha")
          set_error_flash I18n.t("rodauth.did_not_pass_recaptcha_flash_alert")
        end
        super()
      end
    end
  end
end

# https://rodauth.jeremyevans.net/rdoc/files/doc/login_rdoc.html
# https://rodauth.jeremyevans.net/rdoc/files/doc/logout_rdoc.html
module LoginLogout
  extend ActiveSupport::Concern

  included do
    configure do
      enable :login, :logout
      login_route :sign_in
      logout_route :sign_out
      login_param "email"
      login_return_to_requested_location? true

      # Redirect to home page after logout.
      logout_redirect { login_path }

      # Ensure requiring login follows login route changes.
      require_login_redirect { login_path }

      # Redirect to the app from login and registration pages if already logged in.
      already_logged_in do
        # Allow to send reset password email for logged in users.
        redirect "/" unless scope.request.path.in?(%w[/password_recovery /password_new])
      end

      # Replace the error alert if the email or password is invalid.
      login_view do
        if field_error(login_param) || field_error(password_param)
          href = ApplicationController.helpers.link_to(
            I18n.t("rodauth.login_invalid_email_or_password_link_text"), reset_password_request_path
          )
          set_error_flash I18n.t("rodauth.login_invalid_email_or_password", href:)
        end
        super()
      end
    end
  end
end

# https://rodauth.jeremyevans.net/rdoc/files/doc/remember_rdoc.html
module Remember
  extend ActiveSupport::Concern

  included do
    configure do
      enable :remember

      # Remember all logged in users.
      after_login { remember_login }

      # Or only remember users that have ticked a "Remember Me" checkbox on login.
      # after_login { remember_login if param_or_nil("remember") }

      # Extend user's remember period when remembered via a cookie
      extend_remember_deadline? true

      remember_deadline_interval({ days: 7 })
    end
  end
end

# https://rodauth.jeremyevans.net/rdoc/files/doc/verify_account_rdoc.html
# https://rodauth.jeremyevans.net/rdoc/files/doc/verify_account_grace_period_rdoc.html
module VerifyAccount
  extend ActiveSupport::Concern

  included do
    configure do
      enable :verify_account
      verify_account_route :verify_email
      verify_account_resend_route :verify_email_resend
      # Allow to set password for unverified account.
      verify_account_set_password? false
      verify_account_email_sent_redirect do
        verify_account_resend_path(login_param => param(login_param))
      end
      verify_account_email_recently_sent_redirect do
        verify_account_resend_path(login_param => param(login_param))
      end
      # The number of seconds before sending another verify account email
      verify_account_skip_resend_email_within 60

      create_verify_account_email do
        RodauthMailer.verify_account(
          self.class.configuration_name, account_id, verify_account_key_value
        )
      end

      send_verify_account_email do
        # Skip verification email on accepting invitation,
        # since the account is verified in the after_create_account hook.
        return if internal_request? || !CreateAccount::MAILER_ENABLED

        create_verify_account_email.deliver!
      end
    end
  end
end

# https://rodauth.jeremyevans.net/rdoc/files/doc/reset_password_rdoc.html
# https://rodauth.jeremyevans.net/rdoc/files/doc/change_password_rdoc.html
module ManagePassword
  extend ActiveSupport::Concern

  included do
    configure do
      enable :reset_password, :change_password
      change_password_route :change_password
      reset_password_request_route :password_recovery
      reset_password_route :password_new

      reset_password_autologin? true

      # Stay on the same page after requesting a password reset.
      reset_password_email_sent_redirect do
        reset_password_request_route
      end
      reset_password_email_recently_sent_redirect do
        reset_password_request_route
      end

      # Replace the error alert that the email was not found.
      reset_password_request_error_flash do
        if field_error(login_param)
          set_notice_flash reset_password_email_sent_notice_flash
          set_error_flash ""
        else
          super()
        end
      end
    end
  end
end

class RodauthMain < Rodauth::Rails::Auth
  include CreateAccount
  include LoginLogout
  include Remember
  include VerifyAccount
  include ManagePassword

  # rubocop:disable Layout/LineLength
  configure do
    # List of authentication features that are loaded.
    enable :reset_password, :change_password, :internal_request

    translate do |key, default|
      I18n.t("rodauth.#{key}") || default
    end

    require_password_confirmation? true

    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # ==> General
    # Initialize Sequel and have it reuse Active Record's database connection.
    db Sequel.postgres(extensions: :activerecord_connection, keep_reference: false)

    # Avoid DB query that checks accounts table schema at boot time.
    convert_token_id_to_integer? true

    # Change prefix of table and foreign key column names from default "account"
    # accounts_table :users
    # verify_account_table :user_verification_keys
    # verify_login_change_table :user_login_change_keys
    # reset_password_table :user_password_reset_keys
    # remember_table :user_remember_keys
    # rodauth-model by default uses column with name "status", while rodauth-omniauth
    # be default expects column status_id, so need to specify column name explicitly.
    account_status_column :status

    # The secret key used for hashing public-facing tokens for various features.
    # Defaults to Rails `secret_key_base`, but you can use your own secret key.
    # hmac_secret "174dcc5d2be57485c9f805305f8890ba148e0875170e4df227c4a153db7a2f44ca2743305310a571add43c8a527f984421bb5a83faa1d1c823df4f14e56a1bd8"

    # Use path prefix for all routes.
    # prefix "/auth"

    # Specify the controller used for view rendering, CSRF, and callbacks.
    rails_controller { RodauthController }
    rails_account_model { Account }

    # Make built-in page titles accessible in your views via an instance variable.
    title_instance_variable :@page_title

    # Store account status in an integer column without foreign key constraint.
    # account_status_column :status

    # Store password hash in a column instead of a separate table.
    account_password_hash_column :password_hash

    # Set password when creating account instead of when verifying.
    # verify_account_set_password? false

    # Change some default param keys.
    # login_confirm_param "email-confirm"
    # password_confirm_param "confirm_password"

    # Redirect back to originally requested location after authentication.
    # two_factor_auth_return_to_requested_location? true # if using MFA

    # Autologin the user after they have reset their password.
    # reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    # delete_account_on_close? true

    # ==> Emails
    # Use a custom mailer for delivering authentication emails.
    create_reset_password_email do
      RodauthMailer.reset_password(self.class.configuration_name, account_id, reset_password_key_value)
    end
    # create_verify_login_change_email do |_login|
    #   RodauthMailer.verify_login_change(self.class.configuration_name, account_id, verify_login_change_key_value)
    # end
    # create_password_changed_email do
    #   RodauthMailer.password_changed(self.class.configuration_name, account_id)
    # end
    # create_reset_password_notify_email do
    #   RodauthMailer.reset_password_notify(self.class.configuration_name, account_id)
    # end
    # create_email_auth_email do
    #   RodauthMailer.email_auth(self.class.configuration_name, account_id, email_auth_key_value)
    # end
    # create_unlock_account_email do
    #   RodauthMailer.unlock_account(self.class.configuration_name, account_id, unlock_account_key_value)
    # end
    # send_email do |email|
    #   # queue email delivery on the mailer after the transaction commits
    #   db.after_commit { email.deliver_later }
    # end

    # ==> Flash
    # Match flash keys with ones already used in the Rails app.
    # flash_notice_key :success # default is :notice
    # flash_error_key :error # default is :alert

    # Override default flash messages.
    # create_account_notice_flash "Your account has been created. Please verify your account by visiting the confirmation link sent to your email address."
    # require_login_error_flash "Login is required for accessing this page"
    # login_notice_flash nil

    # ==> Validation
    # Override default validation error messages.
    # no_matching_login_message "user with this email address doesn't exist"
    # already_an_account_with_this_login_message "user with this email address already exists"
    # password_too_short_message { "needs to have at least #{password_minimum_length} characters" }
    login_does_not_meet_requirements_message do
      login_requirement_message || t("rodauth.invalid_login_message")
    end

    password_does_not_meet_requirements_message do
      # FIXME: for unknown reason the error message for short password doesn't use text from rodauth.en.
      # Need to find reason and remove this hack.
      message = password_requirement_message || t("rodauth.invalid_password_message")
      "#{message.capitalize.chomp('.')}."
    end

    # Passwords shorter than 8 characters are considered weak according to OWASP.
    # password_minimum_length 8
    # bcrypt has a maximum input length of 72 bytes, truncating any extra bytes.
    # password_maximum_bytes 72

    # Custom password complexity requirements (alternative to password_complexity feature).
    # password_meets_requirements? do |password|
    #   super(password) && password_complex_enough?(password)
    # end
    # auth_class_eval do
    #   def password_complex_enough?(password)
    #     return true if password.match?(/\d/) && password.match?(/[^a-zA-Z\d]/)
    #     set_password_requirement_error_message(:password_simple, "requires one number and one special character")
    #     false
    #   end
    # end

    # ==> Redirects
    # Redirect to wherever login redirects to after account verification.
    # verify_account_redirect { login_redirect }

    # Redirect to login page after password reset.
    # reset_password_redirect { login_path }

    # ==> Deadlines
    # Change default deadlines for some actions.
    # reset_password_deadline_interval Hash[hours: 6]
    # verify_login_change_deadline_interval Hash[days: 2]
  end
  # rubocop:enable Layout/LineLength

  def admin?
    member && member.admin? # rubocop:disable Style/SafeNavigation
  end

  def member?
    member && member.member? # rubocop:disable Style/SafeNavigation
  end

  def active?
    member && member.active? # rubocop:disable Style/SafeNavigation
  end

  def member
    @member ||= Member.find_by(account_id: rails_account[:id])
  end

  def verify_recaptcha
    recaptcha_v3_score = param("recaptcha_v3_score").to_f

    return if RecaptchaV3::ENABLED && recaptcha_v3_score >= RecaptchaV3::MIN_SCORE

    return unless Recaptcha::ENABLED

    # Retrieve this value from `resuest.params` because on production this `param` is blank
    # when the form is submitted with the recaptcha v2.
    recaptcha_v2_response = request.params["g-recaptcha-response"]

    if recaptcha_v2_response.blank?
      return_response(
        rails_render(
          turbo_stream: turbo_stream.update(:turbo_recaptcha, partial: "public/recaptcha_modal")
        )
      )
    elsif recaptcha_v2_response.present?
      # Decided to call the internal method directly because the public method `verify_recaptcha`
      # expects to be called on the controller level.
      # https://github.com/ambethia/recaptcha/blob/master/lib/recaptcha.rb#L61
      unless Recaptcha.verify_via_api_call(recaptcha_v2_response, {})
        throw_error_status(422, "recaptcha", "")
      end
    else
      throw_error_status(422, "recaptcha", "")
    end
  end
end
