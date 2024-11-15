# frozen_string_literal: true

class CandidateLink < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :candidate
  belongs_to :created_by, class_name: "Member", optional: true

  enum :status, %i[
    current
    outdated
  ].index_with(&:to_s), prefix: true

  enum :created_via, %i[
    api
    manual
  ].index_with(&:to_s), prefix: true

  validates :url, presence: true, uniqueness: { scope: :candidate_id }

  before_validation do
    self.url = AccountLink.new(url).normalize
    # To prevent exception in AccountLink#normalize we consider such links invalid.
  rescue Addressable::URI::InvalidURIError
    false
  end

  def to_params
    attributes.symbolize_keys.slice(
      :url,
      :status,
      :added_at,
      :created_by_id,
      :created_via
    )
  end
end
