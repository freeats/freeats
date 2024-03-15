# frozen_string_literal: true

require "test_helper"

class CandidateEmailAddressTest < ActiveSupport::TestCase
  test "creating should work" do
    assert_nothing_raised do
      CandidateEmailAddress.create!(
        candidate: candidates(:john),
        address: "john123@gmail.com",
        list_index: 2,
        type: :personal,
        source: :other,
        status: :outdated
      )
    end
  end

  test "shouldn't create if address with the same list_index already exists" do
    assert_raise ActiveRecord::RecordNotUnique do
      CandidateEmailAddress.create!(
        candidate: candidates(:john),
        address: "john123@gmail.com",
        list_index: 1,
        type: :personal,
        source: :other,
        status: :outdated
      )
    end
  end

  test "address must be valid" do
    assert_raise ActiveRecord::RecordInvalid do
      CandidateEmailAddress.create!(
        candidate: candidates(:john),
        address: "johh_invalid@gmail_com",
        list_index: 2,
        type: :personal,
        source: :other,
        status: :outdated
      )
    end
  end
end
