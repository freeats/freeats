# frozen_string_literal: true

class Member < ApplicationRecord
  belongs_to :account

  enum access_level: %i[inactive interviewer employee hiring_manager admin].index_with(&:to_s)
end
