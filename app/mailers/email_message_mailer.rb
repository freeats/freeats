# frozen_string_literal: true

class EmailMessageMailer < ApplicationMailer
  def send_email
    @html_body = params.delete(:html_body)
    mail(params)
  end
end
