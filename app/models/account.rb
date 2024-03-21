# frozen_string_literal: true

class Account < ApplicationRecord
  include Rodauth::Model(RodauthMain)

  has_one :member, dependent: :destroy

  enum :status, verified: 2, closed: 3 # unverified: 1
end
