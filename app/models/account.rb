# frozen_string_literal: true

class Account < ApplicationRecord
  include Rodauth::Model(RodauthMain)

  has_many :identities, dependent: :destroy
  has_one :member, dependent: :destroy

  has_one_attached :avatar do |attachable|
    attachable.variant(:icon, resize_to_fill: [144, 144], preprocessed: true)
    attachable.variant(:medium, resize_to_fill: [450, 450], preprocessed: true)
  end

  validates :name, presence: true
  validates :email, presence: true

  def rails_admin_name
    email
  end
end
