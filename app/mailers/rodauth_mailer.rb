# frozen_string_literal: true

class RodauthMailer < ApplicationMailer
  default to: -> { @rodauth.email_to }, from: -> { @rodauth.email_from }

  # Examples:
  # def reset_password(name, account_id, key)
  #   @rodauth = rodauth(name, account_id) { @reset_password_key_value = key }
  #   @account = @rodauth.rails_account
  #
  #   mail(subject: @rodauth.email_subject_prefix + @rodauth.reset_password_email_subject)
  # end
  # def password_changed(name, account_id)
  #   @rodauth = rodauth(name, account_id)
  #   @account = @rodauth.rails_account
  #
  #   mail(subject: @rodauth.email_subject_prefix + @rodauth.password_changed_email_subject)
  # end

  private

  def rodauth(name, account_id, &block)
    instance = RodauthApp.rodauth(name).allocate
    instance.instance_eval { @account = account_ds(account_id).first! }
    instance.instance_eval(&block) if block
    instance
  end
end
