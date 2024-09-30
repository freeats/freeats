# frozen_string_literal: true

class MemberInviteMailer < ApplicationMailer
  def invitation
    @invite_token = params[:invite_token]
    @company_name = params[:company_name]
    @platform_name = params[:platform_name]
    mail(subject: "Invitation to join #{@company_name} on #{@platform_name}")
  end
end
