# frozen_string_literal: true

class AccessToken < ApplicationRecord
  include EmailRegexp

  MEMBER_INVITATION_TTL = 4.weeks

  acts_as_tenant(:tenant)

  enum :context, [:member_invitation].index_with(&:to_s)
  validates :hashed_token, :sent_to, :context, presence: true
  validates :sent_to, format: { with: EMAIL_REGEXP }

  def expired?
    case context
    when "member_invitation"
      sent_at.before?(MEMBER_INVITATION_TTL.ago)
    else
      raise NotImplementedError, "Unsupported context"
    end
  end
end
