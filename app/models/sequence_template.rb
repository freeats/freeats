# frozen_string_literal: true

class SequenceTemplate < ApplicationRecord
  acts_as_tenant(:tenant)

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
  has_many :sequences, dependent: :restrict_with_exception
  belongs_to :position

  accepts_nested_attributes_for :stages, allow_destroy: true

  validates :subject, presence: true
  validates :name, presence: true, uniqueness: { scope: %i[position_id] }
  validate :stages_must_be_valid

  scope :not_archived, -> { where(archived: false) }

  before_validation do
    first_stage = stages_without_marked_for_destruction.first

    first_stage.delay_in_days = nil if first_stage.present?
  end

  def stages_without_marked_for_destruction
    stages.reject(&:marked_for_destruction?)
  end

  def present_variables
    @sequence_template_body_sum = stages.each_with_object([]) do |stage, memo|
      memo << stage.body.body.to_html
    end.join(" ")
    LiquidTemplate.new(
      ApplicationController.helpers.unescape_link_tags(
        "#{subject} #{@sequence_template_body_sum}"
      )
    ).present_variables
  end

  def missing_variables(variables)
    missing_variables = present_variables.filter do |var|
      # If var value is false, then false.blank? return true.
      # So additional need to check variables[var] != false.
      variables[var].blank? && variables[var] != false
    end
    checked_missed_variables =
      (missing_variables & LiquidTemplate::OPTIONAL_TEMPLATE_VARIABLE_NAMES).filter do |variable|
        positive_regexp =
          Regexp.new("{%\s*if #{variable}\s*%}.*{{\s*#{variable}\s*}}.*{%\s*endif\s*%}")
        @sequence_template_body_sum.match?(positive_regexp)
      end
    missing_variables - checked_missed_variables
  end

  def build_sequence_data(variables)
    stages.map do |stage|
      body_template = stage.body.body.to_html
      body_template =
        LiquidTemplate.new(
          ApplicationController.new.helpers.unescape_link_tags(body_template)
        ).render(variables)
      subject_template = LiquidTemplate.new(subject).render(variables)

      {
        body: body_template,
        subject: stage.position == 1 ? subject_template : "Re: #{subject_template}",
        position: stage.position,
        delay_in_days: stage.delay_in_days
      }
    end
  end

  private

  def stages_must_be_valid
    stages_to_inspect = stages_without_marked_for_destruction

    positions = stages_to_inspect.map(&:position)
    errors.add(:stages, "must have different positions") if positions.uniq.to_a != positions

    stages_to_inspect.each do |stage|
      if stage.position > 1 && (stage.delay_in_days.nil? || stage.delay_in_days.zero?)
        errors.add(:base, "Stage #{stage.position} must have delay in days specified.")
      end
    end
  end
end
