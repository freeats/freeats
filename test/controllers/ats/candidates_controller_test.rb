# frozen_string_literal: true

require "test_helper"

class ATS::CandidatesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ats_candidates_url

    assert_response :success
  end

  test "should get new" do
    get new_ats_candidate_url

    assert_response :success
  end

  test "should create candidate" do
    full_name = "Bernard Smith"
    assert_difference "Candidate.count" do
      post ats_candidates_path, params: { candidate: { full_name: } }
    end

    new_candidate = Candidate.order(:created_at).last

    assert_redirected_to tab_ats_candidate_path(new_candidate, :info)

    assert_equal new_candidate.full_name, full_name
    assert_equal flash[:notice], "Candidate was successfully created."
  end

  test "should not create candidate" do
    assert_no_difference "Candidate.count" do
      post ats_candidates_path, params: { candidate: { full_name: "" } }
    end

    assert_redirected_to ats_candidates_path
    assert_equal flash[:alert], ["Full name can't be blank"]
  end

  test "should assign the medium and icon avatars and remove them" do
    file = fixture_file_upload("app/assets/images/icons/user.png", "image/png")
    candidate = candidates(:john)
    number_of_created_blobs = 3

    assert_not candidate.avatar.attached?
    assert_nil candidate.avatar.variant(:icon)
    assert_nil candidate.avatar.variant(:medium)

    assert_difference "ActiveStorage::Blob.count", number_of_created_blobs do
      perform_enqueued_jobs do
        patch ats_candidate_path(candidate), params: { candidate: { avatar: file } }
      end
    end

    candidate.reload

    assert_predicate candidate.avatar, :attached?
    assert_not_nil candidate.avatar.variant(:icon)
    assert_not_nil candidate.avatar.variant(:medium)

    ActiveStorage::Blob.last(number_of_created_blobs).each do |blob|
      assert_match(%r{uploads/candidate/#{candidate.id}/.*\.jpg}, blob.key)
    end

    patch ats_candidate_path(candidate), params: { candidate: { remove_avatar: "1" } }

    candidate.reload

    assert_not candidate.avatar.attached?
    assert_nil candidate.avatar.variant(:icon)
    assert_nil candidate.avatar.variant(:medium)
  end

  test "should assign and remove file" do
    file = fixture_file_upload("app/assets/images/icons/user.png", "image/png")
    candidate = candidates(:john)

    assert_not candidate.files.attached?

    assert_difference "ActiveStorage::Blob.count", 1 do
      patch ats_candidate_path(candidate), params: { candidate: { file: } }
    end

    candidate.reload

    assert_predicate candidate.files, :attached?
    assert_match(%r{uploads/candidate/#{candidate.id}/.*\.png}, candidate.files.first.blob.key)

    patch ats_candidate_path(candidate), params: { candidate: { file_id_to_remove: candidate.files.first.id } }

    candidate.reload

    assert_not candidate.files.attached?
  end
end
