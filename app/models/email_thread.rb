# frozen_string_literal: true

class EmailThread < ApplicationRecord
  has_many :messages,
           -> { order(timestamp: :desc) },
           dependent: :destroy,
           inverse_of: :email_thread,
           class_name: "EmailMessage"
  has_many :email_message_addresses, through: :messages

  def candidates_in_thread
    @candidates_in_thread ||= Candidate.with_emails(email_message_addresses.pluck(:address))
  end
end
