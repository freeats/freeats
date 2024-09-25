# frozen_string_literal: true

require "test_helper"

class AccessTokenTest < ActiveSupport::TestCase
  test "expired? should work" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)

    fresh_token =
      create(
        :access_token,
        context: "member_invitation",
        sent_at: (AccessToken::MEMBER_INVITATION_TTL.ago + 1.hour)
      )
    expired_token =
      create(
        :access_token,
        context: "member_invitation",
        sent_at: AccessToken::MEMBER_INVITATION_TTL.ago
      )

    assert_not fresh_token.expired?
    assert_predicate expired_token, :expired?
  end
end
