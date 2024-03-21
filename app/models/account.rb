# frozen_string_literal: true

class Account < ApplicationRecord
  include Rodauth::Model(RodauthMain)
  enum :status, verified: 2, closed: 3 # unverified: 1
end
