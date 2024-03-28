# frozen_string_literal: true

class Account::Identity < ApplicationRecord
  belongs_to :account
end
