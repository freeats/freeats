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

  test "should GET all tabs" do
    candidate = candidates(:ivan)

    get ats_candidate_path(candidate)

    assert_redirected_to tab_ats_candidate_url(candidate, :info)
    get tab_ats_candidate_path(candidate, :info)

    assert_response :success
    get tab_ats_candidate_path(candidate, :emails)

    assert_response :success
    get tab_ats_candidate_path(candidate, :scorecards)

    assert_response :success
    get tab_ats_candidate_path(candidate, :files)

    assert_response :success
    get tab_ats_candidate_path(candidate, :activities)

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
        patch update_header_ats_candidate_path(candidate), params: { candidate: { avatar: file } }
      end
    end

    candidate.reload

    assert_predicate candidate.avatar, :attached?
    assert_not_nil candidate.avatar.variant(:icon)
    assert_not_nil candidate.avatar.variant(:medium)

    ActiveStorage::Blob.last(number_of_created_blobs).each do |blob|
      assert_match(%r{uploads/candidate/#{candidate.id}/.*}, blob.key)
    end

    delete remove_avatar_ats_candidate_path(candidate)

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

  test "should strip string fields before saving candidate on create" do
    skip "Only full_name is stripped atm"
    new_candidate = {
      full_name: "   Name   ",
      company: "   Company name   ",
      telegram: "  @telegram   ",
      skype: "  skype  ",
      cover_letter: "  Some text  "
    }

    post ats_candidates_path, params: { candidate: new_candidate }
    candidate = Candidate.order(:created_at).last

    assert_equal candidate.full_name, new_candidate[:full_name].strip
    assert_equal candidate.company, new_candidate[:company].strip
    assert_equal candidate.telegram, new_candidate[:telegram].strip
    assert_equal candidate.skype, new_candidate[:skype].strip
    assert_equal candidate.cover_letter.to_plain_text, new_candidate[:cover_letter].strip
  end

  test "should update profile header card" do
    candidate = candidates(:jane)

    assert_equal candidate.full_name, "Jane Doe"
    assert_empty candidate.headline
    assert_not candidate.company
    assert_not candidate.blacklisted
    assert_equal candidate.location, locations(:moscow_city)

    patch(
      update_header_ats_candidate_path(candidate),
      params: {
        candidate: {
          full_name: "Vasya",
          headline: "new headline",
          company: "New awesome company",
          blacklisted: true,
          location_id: locations(:valencia_city).id
        }
      }
    )

    assert_response :success
    candidate.reload

    assert_equal candidate.full_name, "Vasya"
    assert_equal candidate.headline, "new headline"
    assert_equal candidate.company, "New awesome company"
    assert candidate.blacklisted
    assert_equal candidate.location, locations(:valencia_city)
  end

  test "should update profile card contact_info" do
    candidate = candidates(:ivan)
    card_patch = {
      source: "LinkedIn",
      candidate_email_addresses_attributes: {
        "0" => {
          address: "sherlock@gmail.com",
          source: "other",
          type: "personal",
          status: "current"
        },
        "1" => {
          address: "sherlock@yandex.ru",
          source: "other",
          type: "personal",
          status: "invalid"
        },
        "2" => {
          address: "Sherlock@yandex.ru",
          source: "other",
          type: "personal",
          status: "outdated"
        }
      },
      candidate_phones_attributes: {
        "0" => {
          phone: "+79259283344",
          source: "other",
          type: "personal",
          status: "current"
        }
      },
      candidate_links_attributes: {
        "0" => {
          url: "https://www.linkedin.com/in/monsher/",
          status: "current"
        }
      }
    }
    patch update_card_ats_candidate_path(candidate),
          params: { card_name: "contact_info", candidate: card_patch }

    assert_response :success

    candidate.reload

    assert_equal candidate.source, "LinkedIn"
    assert_equal candidate.candidate_emails.sort,
                 card_patch[:candidate_email_addresses_attributes].values.pluck(:address)
                                                                  .map(&:downcase).uniq.sort
    assert_equal candidate.phones.sort,
                 card_patch[:candidate_phones_attributes].values.pluck(:phone).sort
    assert_equal candidate.links.sort,
                 card_patch[:candidate_links_attributes].values.pluck(:url).sort
  end

  test "should update profile card cover_letter" do
    candidate = candidates(:ivan)
    card_patch = {
      cover_letter: "I'm Vasya"
    }
    patch update_card_ats_candidate_path(candidate),
          params: { card_name: "cover_letter", candidate: card_patch }

    assert_response :success
    candidate.reload

    assert_equal candidate.cover_letter.to_plain_text, card_patch[:cover_letter]
  end

  test "adding a dot to an existing email address should keep its object and its email_messages" do
    skip "Not enough data yet."

    email_address = person_email_addresses(:jack_london1)
    candidate = email_address.candidate

    person_phones_attributes = candidate.person_phones.map.with_index do |phone, idx|
      { idx.to_s => phone.attributes.slice("phone", "type", "status", "source") }
    end.reduce({}, :merge)
    person_links_attributes = candidate.person_links.map.with_index do |link, idx|
      { idx.to_s => link.attributes.slice("url", "status") }
    end.reduce({}, :merge)

    assert_equal email_address.address, "jack_london@gmail.com"
    assert_predicate EmailMessage.messages_to_addresses(to: email_address.address), :exists?

    new_address = "jack_lon.don@gmail.com"

    patch update_card_hub_candidate_path(candidate),
          params: {
            card_name: "contact_info",
            candidate: {
              person_phones_attributes:,
              person_links_attributes:,
              email_addresses_attributes: {
                "0" => { id: email_address.id,
                         source: email_address.source,
                         type: email_address.type,
                         address: new_address }
              }
            }
          }

    email_address.reload

    assert_equal email_address.address, new_address
    assert_predicate EmailMessage.messages_to_addresses(to: new_address), :exists?
  end

  test "should assign and unassign recruiter for candidate" do
    actor_user = accounts(:admin_account)
    sign_in actor_user

    candidate = Candidate.first
    recruiter1 = members(:admin_member)
    recruiter2 = members(:employee_member)

    candidate.update!(recruiter_id: nil)

    patch assign_recruiter_ats_candidate_path(candidate.id),
          params: { candidate: { recruiter_id: recruiter1.id } }

    assert_equal candidate.reload.recruiter_id, recruiter1.id

    # TODO: uncomment if events have been added.
    # Event.last.tap do |event|
    #   assert_equal event.type, "candidate_responsible_assigned"
    #   assert_equal event.actor_user_id, actor_user_id
    #   assert_equal event.member_id, recruiter1.id
    #   assert_equal event.person_id, candidate.id
    # end

    patch assign_recruiter_ats_candidate_path(candidate.id),
          params: { candidate: { recruiter_id: recruiter2.id } }

    assert_equal candidate.reload.recruiter_id, recruiter2.id

    # TODO: uncomment if events have been added.
    # TODO: Add asserts for candidate_responsible_unassigned event
    # Event.last.tap do |event|
    #   assert_equal event.type, "candidate_responsible_assigned"
    #   assert_equal event.actor_user_id, actor_user_id
    #   assert_equal event.member_id, recruiter2.id
    #   assert_equal event.person_id, candidate.id
    # end

    patch assign_recruiter_ats_candidate_path(candidate.id),
          params: { candidate: { recruiter_id: nil } }

    assert_nil candidate.reload.recruiter_id

    # TODO: uncomment if events have been added.
    # Event.last.tap do |event|
    #   assert_equal event.type, "person_responsible_unassigned"
    #   assert_equal event.actor_user_id, actor_user_id
    #   assert_equal event.member_id, recruiter2.id
    #   assert_equal event.person_id, candidate.id
    # end
  end
end
