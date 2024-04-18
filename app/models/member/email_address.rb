# frozen_string_literal: true

class Member::EmailAddress < ApplicationRecord
  belongs_to :member

  validates :address, presence: true
end
