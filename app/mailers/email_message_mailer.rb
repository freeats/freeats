# frozen_string_literal: true

class EmailMessageMailer < ApplicationMailer
  def send_email
    @html_body = params[:html_body]
    mail(params.except(:html_body))
  end
end
