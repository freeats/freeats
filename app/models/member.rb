# frozen_string_literal: true

class Member < ApplicationRecord
  has_and_belongs_to_many :collaborator_positions,
                          class_name: "Position",
                          foreign_key: :collaborator_id,
                          join_table: :positions_collaborators
  has_many :positions,
           inverse_of: :recruiter,
           foreign_key: :recruiter_id,
           dependent: :restrict_with_exception

  belongs_to :account

  enum access_level: %i[inactive interviewer employee hiring_manager admin].index_with(&:to_s)

  scope :active, -> { where.not(access_level: :inactive) }
end
