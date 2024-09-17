# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  helper_method :account_name
  helper :mailer
  helper :main

  default from: '"Toughbyte" <doreply@toughbyte.com>',
          to: -> { @to },
          cc: -> { @cc },
          reply_to: -> { @reply_to }

  layout "mailer"

  before_action :report_about_inactive_member
  before_action :set_headers

  before_action do
    @current_account = params[:current_account]
  end

  private

  def account_name(account)
    account&.name || "Hub"
  end

  def set_headers
    @to = Array(params[:to]).map { format_address(_1) }
    @cc = Array(params[:cc]).map { format_address(_1) }
    @reply_to = Array(params[:reply_to]).map { format_address(_1) }
  end

  def report_about_inactive_member
    (Array(params[:to]) +
     Array(params[:cc]) +
     Array(params[:reply_to])).each do |addressable|
      member =
        if addressable.is_a?(String)
          Member.find_by_address(addressable)
        elsif addressable.is_a?(Member)
          addressable
        end

      next unless member&.inactive?

      ATS::Logger.new(where: "SendMessage")
                 .external_log(
                   "Inactive member in email",
                   member_id: member.id
                 )
      break
    end
  end

  def format_address(addressable)
    if addressable.is_a?(String)
      addressable
    elsif addressable.is_a?(Member)
      email_address = addressable.email_address
      raise "No email address for #{addressable.inspect}" if email_address.nil?

      %("#{addressable.account.name}" <#{email_address}>)
    else
      raise "Invalid addressable supplied for #{self.class}##{action_name}: #{addressable.inspect}"
    end
  end
end
