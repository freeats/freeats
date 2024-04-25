# frozen_string_literal: true

class SequenceTemplate < ApplicationRecord
  DEFAULT_STAGES = [
    { position: 1, delay_in_days: 0 },
    { position: 2, delay_in_days: 3 },
    { position: 3, delay_in_days: 5 }
  ].freeze

  has_many :stages,
           -> { order(:position) },
           class_name: "SequenceTemplateStage",
           inverse_of: :sequence_template,
           dependent: nil
  belongs_to :position

  accepts_nested_attributes_for :stages, allow_destroy: true

  validates :subject, presence: true
  validates :name, presence: true, uniqueness: { scope: %i[position_id] }
  validate :stages_must_be_valid

  scope :not_archived, -> { where(archived: false) }

  before_validation do
    stages.first.delay_in_days = nil if stages.first.present?
  end

  private

  def stages_must_be_valid
    stages_to_inspect = stages.reject(&:marked_for_destruction?)

    positions = stages_to_inspect.map(&:position)
    errors.add(:stages, "must have different positions") if positions.uniq.to_a != positions

    stages_to_inspect.each do |stage|
      if stage.position > 1 && (stage.delay_in_days.nil? || stage.delay_in_days.zero?)
        errors.add(:base, "Stage #{stage.position} must have delay in days specified.")
      end
    end
  end
end
