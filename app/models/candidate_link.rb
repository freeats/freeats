# frozen_string_literal: true

class CandidateLink < ApplicationRecord
  belongs_to :candidate

  enum status: %i[
    current
    outdated
  ].index_with(&:to_s), _prefix: true

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
      :status
    )
  end
end
