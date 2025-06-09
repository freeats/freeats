# frozen_string_literal: true

class EnabledFeature < ApplicationRecord
  belongs_to :tenant

  enum :name, %i[
    emails
  ].index_with(&:to_s)
  validates :name, presence: true
  validates :name, uniqueness: { scope: :tenant_id }
end
