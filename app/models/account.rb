# frozen_string_literal: true

class Account < ApplicationRecord
  include Rodauth::Model(RodauthMain)

  has_one :member, dependent: :destroy

  has_one_attached :avatar do |attachable|
    attachable.variant(:icon, resize_to_fill: [144, 144], preprocessed: true)
    attachable.variant(:medium, resize_to_fill: [450, 450], preprocessed: true)
  end

  enum :status, verified: 2, closed: 3 # unverified: 1

  validates :name, presence: true
end
