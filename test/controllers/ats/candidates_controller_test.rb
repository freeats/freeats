# frozen_string_literal: true

require "test_helper"

class ATS::CandidatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:employee_account)
  end

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
    skip "Unskip when we implement logic to assign avatar to the candidate"

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
      post upload_file_ats_candidate_path(candidate), params: { candidate: { file: } }
    end

    candidate.reload

    assert_predicate candidate.files, :attached?
    assert_match(%r{uploads/candidate/#{candidate.id}/.*\.png}, candidate.files.first.blob.key)

    delete delete_file_ats_candidate_path(candidate, candidate: { file_id_to_remove: candidate.files.first.id })

    candidate.reload

    assert_not candidate.files.attached?
  end

  test "should upload candidate file and remove it" do
    candidate = candidates(:john)

    assert_empty candidate.files

    file = fixture_file_upload("empty.pdf", "application/pdf")
    assert_difference "ActiveStorage::Blob.count" do
      post upload_file_ats_candidate_path(candidate), params: { candidate: { file: } }
    end

    assert_response :redirect
    assert_equal candidate.files.last.id, ActiveStorage::Attachment.last.id

    file_id_to_remove = candidate.files.last.id
    assert_difference "ActiveStorage::Blob.count", -1 do
      delete delete_file_ats_candidate_path(candidate), params: { candidate: { file_id_to_remove: } }
    end

    assert_response :success
    assert_empty candidate.files
  end

  test "should set file as cv and then reassign the cv flag to another file" do
    candidate = candidates(:jane)
    attachment = candidate.files.last

    assert_equal candidate.files.count, 1

    assert_not candidate.cv

    patch change_cv_status_ats_candidate_path(candidate),
          params: { candidate: { file_id_to_change_cv_status: attachment.id,
                                 new_cv_status: true } }

    assert_response :success
    candidate.reload

    assert_predicate candidate.cv, :present?

    # Attach new file and make him CV
    new_cv_file = fixture_file_upload("empty.pdf", "application/pdf")
    assert_difference "ActiveStorage::Blob.count" do
      post upload_file_ats_candidate_path(candidate), params: { candidate: { file: new_cv_file } }
    end

    assert_response :redirect

    new_attachment = candidate.files.last
    patch change_cv_status_ats_candidate_path(candidate),
          params: { candidate: { file_id_to_change_cv_status: new_attachment.id,
                                 new_cv_status: true } }

    assert_response :success

    assert_not attachment.attachment_information.is_cv
    assert new_attachment.attachment_information.is_cv
  end

  test "should delete cv file" do
    candidate = candidates(:jane)
    attachment = candidate.files.last

    assert_not candidate.cv

    attachment.change_cv_status(true)

    assert candidate.cv

    delete delete_cv_file_ats_candidate_path(candidate), params: { candidate: { file_id_to_remove: attachment.id } }

    assert_response :redirect
    assert_not candidate.cv
    assert_not candidate.files.attached?
  end

  test "should download cv file" do
    skip "For some reason this test is failing in GitHub CI, but it's working locally."

    candidate = candidates(:jane)
    attachment = candidate.files.last

    attachment.change_cv_status(true)

    assert candidate.cv

    get download_cv_file_ats_candidate_path(candidate)

    assert_response :success
    assert_equal response.content_type, "application/pdf"
  end

  test "should upload cv file" do
    candidate = candidates(:john)

    assert_not candidate.files.attached?
    assert_not candidate.cv

    file = fixture_file_upload("empty.pdf", "application/pdf")
    post upload_cv_file_ats_candidate_path(candidate), params: { candidate: { file: } }

    assert_response :redirect
    assert_predicate candidate.files, :attached?
    assert candidate.cv
  end
end
