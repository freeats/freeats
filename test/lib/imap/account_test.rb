# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class ImapAccountTest < ActiveSupport::TestCase
  test "imap_service should retry to fetch access token if it fails" do
    WebMock.reset!
    oauth_client_mock = Minitest::Mock.new
    4.times do
      oauth_client_mock.expect :fetch_access_token!, [] do
        raise Signet::AuthorizationError, "auth error"
      end
    end
    oauth_client_mock.expect :fetch_access_token!, true
    oauth_client_mock.expect :access_token, "token"

    Gmail::Auth.stub :with_tokens, oauth_client_mock do
      Imap::Account.stub_const(:AUTHORIZATION_RETRY_DELAY, 0) do
        assert_not_equal members(:admin_member).imap_account.imap_service, nil
      end
    end

    oauth_client_mock.verify
  end
end
