# frozen_string_literal: true

class EmailTemplate < ApplicationRecord
  acts_as_tenant(:tenant)

  has_rich_text :message

  strip_attributes only: :name, collapse_spaces: true

  validates :name, presence: true
  validates :message, presence: true
  validate :liquid_template_must_be_valid

  def liquid_template_must_be_valid
    liquid_template =
      LiquidTemplate
      .new(
        ApplicationController.helpers.unescape_link_tags(message.body.to_html),
        type: :email_template
      )
    liquid_template.warnings.each { errors.add(:message, _1) } if liquid_template.warnings.present?
  end
end
