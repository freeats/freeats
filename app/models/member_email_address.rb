# frozen_string_literal: true

class MemberEmailAddress < ApplicationRecord
  belongs_to :member

  validates :address, presence: true
  validates :token, presence: true
  validates :refresh_token, presence: true
end
