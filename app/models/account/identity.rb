# frozen_string_literal: true

class Account::Identity < ApplicationRecord
  belongs_to :account

  def rails_admin_name
    "#{account&.email}|#{provider}|#{uid}"
  end
end
