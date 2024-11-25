# frozen_string_literal: true

class Scorecard < ApplicationRecord
  acts_as_tenant(:tenant)

  has_many :scorecard_questions,
           -> { order(:list_index) },
           dependent: :destroy,
           inverse_of: :scorecard
  has_many :events, as: :eventable, dependent: :destroy
  has_one :added_event,
          -> { where(type: :scorecard_added) },
          class_name: "Event",
          as: :eventable,
          inverse_of: false,
          dependent: nil
  belongs_to :position_stage
  belongs_to :placement
  belongs_to :interviewer, class_name: "Member"

  has_rich_text :summary

  accepts_nested_attributes_for :scorecard_questions

  enum :score, %i[
    irrelevant
    relevant
    good
    perfect
  ].index_with(&:to_s)

  validates :title, presence: true
  validates :score, presence: true

  def author
    Member
      .joins(
        <<~SQL
          JOIN events ON events.actor_account_id = members.account_id
            AND events.type = 'scorecard_added'
            AND events.eventable_id = #{id}
            AND events.eventable_type = 'Scorecard'
        SQL
      )
      .first
  end
end
