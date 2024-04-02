# frozen_string_literal: true

class Account < ApplicationRecord
  include Rodauth::Model(RodauthMain)
  include Avatar

  has_many :identities, dependent: :destroy
  has_one :member, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true

  # Needed for Rails Admin to teach how to delete the avatar.
  attr_accessor :remove_avatar

  after_save { avatar.purge if remove_avatar == "1" }

  def rails_admin_name
    email
  end
end
