# frozen_string_literal: true

require "test_helper"

class ATS::CandidatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_account = accounts(:employee_account)
    sign_in @current_account
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
    candidate = candidates(:jake)

    get ats_candidate_path(candidate)

    assert_redirected_to tab_ats_candidate_url(candidate, :info)
    get tab_ats_candidate_path(candidate, :info)

    assert_response :success
    get tab_ats_candidate_path(candidate, :tasks)

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
      assert_difference "Event.where(type: 'candidate_added').count" do
        post ats_candidates_path, params: { candidate: { full_name: } }
      end
    end

    new_candidate = Candidate.order(:created_at).last

    assert_redirected_to tab_ats_candidate_path(new_candidate, :info)

    assert_equal new_candidate.full_name, full_name
    assert_equal flash[:notice], "Candidate was successfully created."
  end

  test "should not create candidate if full_name is blank" do
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
      assert_match(%r{.*/avatar\.png}, blob.key)
    end

    delete remove_avatar_ats_candidate_path(candidate)

    candidate.reload

    assert_not candidate.avatar.attached?
    assert_nil candidate.avatar.variant(:icon)
    assert_nil candidate.avatar.variant(:medium)
  end

  test "should assign and remove file and create events and update last_activity_at" do
    file = fixture_file_upload("app/assets/images/icons/user.png", "image/png")
    candidate = candidates(:john)

    assert_predicate candidate.last_activity_at, :today?
    assert_not candidate.files.attached?

    travel_to Time.zone.now.days_since(1) do
      assert_difference "ActiveStorage::Blob.count" do
        assert_difference "Event.where(type: 'active_storage_attachment_added').count" do
          post upload_file_ats_candidate_path(candidate), params: { candidate: { file: } }
        end
      end
    end

    candidate.reload

    assert_predicate candidate.files, :attached?
    assert_match(%r{.*/user\.png}, candidate.files.first.blob.key)
    assert_predicate candidate.last_activity_at, :tomorrow?

    travel_to Time.zone.now.days_since(2) do
      assert_difference "Event.where(type: 'active_storage_attachment_removed').count" do
        delete delete_file_ats_candidate_path(candidate, candidate: { file_id_to_remove: candidate.files.first.id })
      end
    end

    candidate.reload

    assert_not candidate.files.attached?
    assert_equal candidate.last_activity_at.to_date, 2.days.from_now.to_date
  end

  test "should upload candidate file and remove it" do
    candidate = candidates(:john)

    assert_empty candidate.files

    file = fixture_file_upload("empty.pdf", "application/pdf")
    assert_difference "ActiveStorage::Blob.count" do
      assert_difference "Event.where(type: 'active_storage_attachment_added').count" do
        post upload_file_ats_candidate_path(candidate), params: { candidate: { file: } }
      end
    end

    assert_response :redirect
    assert_equal candidate.files.last.id, ActiveStorage::Attachment.last.id

    file_id_to_remove = candidate.files.last.id
    assert_difference "ActiveStorage::Blob.count", -1 do
      assert_difference "Event.where(type: 'active_storage_attachment_removed').count" do
        delete delete_file_ats_candidate_path(candidate), params: { candidate: { file_id_to_remove: } }
      end
    end

    assert_response :success
    assert_empty candidate.files
  end

  test "should set file as cv and then reassign the cv flag to another file" do
    candidate = candidates(:jane)
    attachment = candidate.files.last

    assert_equal candidate.files.count, 1
    assert_predicate candidate.last_activity_at, :today?
    assert_not candidate.cv

    travel_to Time.zone.now.days_since(1) do
      assert_difference "Event.where(type: 'candidate_changed').count" do
        patch change_cv_status_ats_candidate_path(candidate),
              params: { candidate: { file_id_to_change_cv_status: attachment.id } }
      end
    end

    assert_response :success
    candidate.reload

    assert_predicate candidate.cv, :present?
    assert_predicate candidate.last_activity_at, :tomorrow?

    # Attach new file and make it a CV
    new_cv_file = fixture_file_upload("empty.pdf", "application/pdf")
    assert_difference "ActiveStorage::Blob.count" do
      post upload_file_ats_candidate_path(candidate), params: { candidate: { file: new_cv_file } }
    end

    assert_response :redirect

    new_attachment = candidate.files.last
    patch change_cv_status_ats_candidate_path(candidate),
          params: { candidate: { file_id_to_change_cv_status: new_attachment.id } }

    assert_response :success

    assert_not attachment.attachment_information.is_cv
    assert new_attachment.attachment_information.is_cv
  end

  test "should delete cv file" do
    candidate = candidates(:jane)
    attachment = candidate.files.last

    assert_not candidate.cv

    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    attachment.change_cv_status

    assert candidate.cv

    assert_difference "Event.where(type: 'active_storage_attachment_removed').count" do
      delete delete_cv_file_ats_candidate_path(candidate), params: { candidate: { file_id_to_remove: attachment.id } }
    end

    assert_response :redirect
    assert_not candidate.cv
    assert_not candidate.files.attached?
  end

  test "should download cv file" do
    skip "For some reason this test is failing in GitHub CI, but it's working locally."

    candidate = candidates(:jane)
    attachment = candidate.files.last

    attachment.change_cv_status

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
    assert_difference "Event.where(type: 'active_storage_attachment_added').count" do
      post upload_cv_file_ats_candidate_path(candidate), params: { candidate: { file: } }
    end

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

  test "should update profile header card, create events and update last_activity_at" do
    candidate = candidates(:jane)

    old_alternative_names = candidate.candidate_alternative_names.pluck(:name)
    new_alternative_names = %w[name1 name2 name3]
    # rubocop:disable Lint/SymbolConversion
    candidate_alternative_names_attributes =
      {
        "0": { "name": "name1" },
        "1": { "name": "name2" },
        "2": { "name": "name3" },
        "id": { "name": "" }
      }
    # rubocop:enable Lint/SymbolConversion

    assert_predicate candidate.last_activity_at, :today?
    assert_equal candidate.full_name, "Jane Doe"
    assert_empty candidate.headline
    assert_empty candidate.company
    assert_not candidate.blacklisted
    assert_equal candidate.location, locations(:helsinki_city)
    assert_not_equal old_alternative_names, new_alternative_names

    travel_to Time.zone.now.days_since(1) do
      assert_difference "Event.where(type: 'candidate_changed').count", 6 do
        patch(
          update_header_ats_candidate_path(candidate),
          params: {
            candidate: {
              full_name: "New Awesome Name",
              headline: "new headline",
              company: "New awesome company",
              blacklisted: true,
              location_id: locations(:valencia_city).id,
              candidate_alternative_names_attributes:
            }
          }
        )
      end
    end

    assert_response :success

    events = Event.last(6)

    assert_equal events.first.eventable, candidate
    assert_equal events.first.changed_field, "alternative_names"
    assert_equal events.first.changed_from, ["Jenek"]
    assert_equal events.first.changed_to, %w[name1 name2 name3]

    assert_equal events.second.eventable, candidate
    assert_equal events.second.changed_field, "location"
    assert_equal events.second.changed_from, "Helsinki, Finland"
    assert_equal events.second.changed_to, "València, Spain"

    assert_equal events.third.eventable, candidate
    assert_equal events.third.changed_field, "full_name"
    assert_equal events.third.changed_from, "Jane Doe"
    assert_equal events.third.changed_to, "New Awesome Name"

    assert_equal events.fourth.eventable, candidate
    assert_equal events.fourth.changed_field, "company"
    assert_empty events.fourth.changed_from
    assert_equal events.fourth.changed_to, "New awesome company"

    assert_equal events.fifth.eventable, candidate
    assert_equal events.fifth.changed_field, "blacklisted"
    assert_not events.fifth.changed_from
    assert events.fifth.changed_to

    assert_equal events.last.eventable, candidate
    assert_equal events.last.changed_field, "headline"
    assert_empty events.last.changed_from
    assert_equal events.last.changed_to, "new headline"

    candidate.reload

    assert_predicate candidate.last_activity_at, :tomorrow?
    assert_equal candidate.full_name, "New Awesome Name"
    assert_equal candidate.headline, "new headline"
    assert_equal candidate.company, "New awesome company"
    assert candidate.blacklisted
    assert_equal candidate.location, locations(:valencia_city)
    assert_equal candidate.candidate_alternative_names.pluck(:name).sort,
                 new_alternative_names.sort
  end

  test "should update profile card contact_info and create events" do
    candidate = candidates(:jake)
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
          address: "sherlock@google.com",
          source: "other",
          type: "personal",
          status: "invalid"
        },
        "2" => {
          address: "Sherlock@google.com",
          source: "other",
          type: "personal",
          status: "outdated"
        }
      },
      candidate_phones_attributes: {
        "0" => {
          phone: "+11111111111",
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

    assert_difference "Event.where(type: 'candidate_changed').count", 4 do
      patch update_card_ats_candidate_path(candidate),
            params: { card_name: "contact_info", candidate: card_patch }
    end

    assert_response :success

    events = Event.last(4)

    assert_equal events.first.eventable, candidate
    assert_equal events.first.changed_field, "candidate_source"
    assert_nil events.first.changed_from
    assert_equal events.first.changed_to, "LinkedIn"

    assert_equal events.second.eventable, candidate
    assert_equal events.second.changed_field, "email_addresses"
    assert_equal events.second.changed_from, ["jake@trujillo.com"]
    assert_equal events.second.changed_to, ["sherlock@gmail.com", "sherlock@google.com"]

    assert_equal events.third.eventable, candidate
    assert_equal events.third.changed_field, "phones"
    assert_empty events.third.changed_from
    assert_equal events.third.changed_to, ["+11111111111"]

    assert_equal events.fourth.eventable, candidate
    assert_equal events.fourth.changed_field, "links"
    assert_empty events.fourth.changed_from
    assert_equal events.fourth.changed_to, ["https://www.linkedin.com/in/monsher/"]

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
    candidate = candidates(:jake)
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

  test "should keep the same created_by, added_at values and entity for the email address" do
    candidate = candidates(:john)
    old_email_address = candidate_email_addresses(:john_email_address1)

    old_created_by = old_email_address.created_by
    old_added_at = old_email_address.added_at
    old_address = old_email_address.address
    new_address = old_address.upcase

    assert_equal old_email_address.created_via, "manual"
    assert_not_equal old_address, new_address
    assert_not_equal @current_account.member, old_created_by
    assert old_created_by
    assert old_added_at

    assert_no_difference "EmailMessage.count" do
      assert_difference "CandidateEmailAddress.count" => -1 do
        patch update_card_ats_candidate_path(candidate),
              params: {
                card_name: "contact_info",
                candidate: {
                  person_phones_attributes: { "0" => { phone: "" } },
                  person_links_attributes: { "0" => { url: "" } },
                  candidate_email_addresses_attributes: {
                    "0" => { source: old_email_address.source,
                             type: old_email_address.type,
                             created_via: "manual",
                             status: old_email_address.status,
                             address: new_address }
                  }
                }
              }
      end
    end

    old_email_address.reload

    assert_equal old_email_address.created_by, old_created_by
    assert_equal old_email_address.added_at, old_added_at
  end

  test "should assign and unassign recruiter for candidate, create event and update last_activity_at" do
    actor_account = accounts(:admin_account)
    sign_out
    sign_in actor_account

    candidate = Candidate.first
    recruiter1 = members(:admin_member)
    recruiter2 = members(:employee_member)

    candidate.update!(recruiter_id: nil, last_activity_at: 2.days.ago)

    assert_difference "Event.where(type: 'candidate_recruiter_assigned').count" do
      patch assign_recruiter_ats_candidate_path(candidate.id),
            params: { candidate: { recruiter_id: recruiter1.id } }
    end

    assert_equal candidate.reload.recruiter_id, recruiter1.id
    assert_predicate candidate.last_activity_at, :today?

    Event.last.tap do |event|
      assert_equal event.type, "candidate_recruiter_assigned"
      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.changed_to, recruiter1.id
      assert_equal event.eventable, candidate
    end

    travel_to Time.zone.now.days_since(1) do
      assert_difference "Event.where(type: 'candidate_recruiter_unassigned').count" do
        assert_difference "Event.where(type: 'candidate_recruiter_assigned').count" do
          patch assign_recruiter_ats_candidate_path(candidate.id),
                params: { candidate: { recruiter_id: recruiter2.id } }
        end
      end
    end

    assert_equal candidate.reload.recruiter_id, recruiter2.id
    assert_predicate candidate.last_activity_at, :tomorrow?

    Event.last(2).tap do |recruiter_unassigned_event, recruiter_assigned_event|
      assert_equal recruiter_unassigned_event.type, "candidate_recruiter_unassigned"
      assert_equal recruiter_unassigned_event.actor_account_id, actor_account.id
      assert_equal recruiter_unassigned_event.changed_from, recruiter1.id
      assert_equal recruiter_unassigned_event.eventable, candidate

      assert_equal recruiter_assigned_event.type, "candidate_recruiter_assigned"
      assert_equal recruiter_assigned_event.actor_account_id, actor_account.id
      assert_equal recruiter_assigned_event.changed_to, recruiter2.id
      assert_equal recruiter_assigned_event.eventable, candidate
    end

    assert_difference "Event.where(type: 'candidate_recruiter_unassigned').count" do
      patch assign_recruiter_ats_candidate_path(candidate.id),
            params: { candidate: { recruiter_id: nil } }
    end

    assert_nil candidate.reload.recruiter_id

    Event.last.tap do |event|
      assert_equal event.type, "candidate_recruiter_unassigned"
      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.changed_from, recruiter2.id
      assert_equal event.eventable, candidate
    end
  end

  test "should show merge_duplicates_modal" do
    sign_in accounts(:admin_account)

    candidate = candidates(:john)

    candidate_duplicate = candidate.not_merged_duplicates.first

    get merge_duplicates_modal_ats_candidate_path(candidate)

    assert_response :success
    assert_includes response.body, "Merge profiles?"
    assert_includes(
      response.body,
      "Profile <b>#{candidate_duplicate.full_name}</b> will be merged with the current " \
      "<b>#{candidate.full_name}</b> profile."
    )
    assert_includes response.body, "Cancel"
    assert_includes response.body, "Merge"
  end

  test "should get redirected to other candidate if current one was merged" do
    sign_in accounts(:admin_account)

    candidate = candidates(:john)
    candidate_duplicate = candidate.not_merged_duplicates.first
    candidate_duplicate.update(merged_to: candidate.id)

    %i[info emails scorecards files activities].each do |tab|
      get tab_ats_candidate_path(candidate_duplicate, tab)

      assert_redirected_to tab_ats_candidate_path(candidate, tab)
      assert_equal flash[:warning],
                   "Candidate you were trying to access was merged with this candidate."
    end
  end

  test "should display scorecard only for associated placement" do
    sign_in accounts(:admin_account)

    ruby_placement1 = placements(:sam_ruby_replied)
    ruby_placement1_scorecard_path = ats_scorecard_path(scorecards(:ruby_position_replied_scorecard))
    ruby_placement2 = placements(:sam_ruby_contacted)
    candidate = candidates(:sam)

    get tab_ats_candidate_path(candidate, :scorecards)

    assert_equal [ruby_placement1.candidate_id, ruby_placement2.candidate_id].uniq, [candidate.id]
    assert_equal ruby_placement1.position_id, ruby_placement2.position_id

    assert_response :success

    ruby_placement1_dom_links = css_select("#placement-#{ruby_placement1.id} a").map { _1.attr("href") }
    ruby_placement2_dom_links = css_select("#placement-#{ruby_placement2.id} a").map { _1.attr("href") }

    assert_includes ruby_placement1_dom_links, ruby_placement1_scorecard_path
    assert_not_includes ruby_placement2_dom_links, ruby_placement1_scorecard_path
  end

  test "should display only stages with scorecard template and one of the next conditions is true: " \
       "stage below or equal placement stage or stage already have scorecard" do
    sign_in accounts(:admin_account)

    # Stage below or equal placement stage.
    ruby_placement = placements(:sam_ruby_contacted)
    candidate = candidates(:sam)

    assert_equal ruby_placement.candidate_id, candidate.id
    assert_equal ruby_placement.stage, "Contacted"

    get tab_ats_candidate_path(candidate, :scorecards)

    assert_response :success

    visible_stage_names = css_select("#placement-#{ruby_placement.id} .text-gray-600").map(&:text)

    assert_equal visible_stage_names, %w[Sourced Contacted]

    # Stage already have scorecard.
    replied_scorecard = scorecards(:ruby_position_replied_scorecard)
    replied_scorecard.update!(placement_id: ruby_placement.id)

    assert_operator(
      ruby_placement.position_stage.list_index, :<, replied_scorecard.position_stage.list_index
    )

    get tab_ats_candidate_path(candidate, :scorecards)

    assert_response :success

    visible_stage_names = css_select("#placement-#{ruby_placement.id} .text-gray-600").map(&:text)

    assert_equal visible_stage_names, %w[Sourced Contacted Replied]

    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    # Stage "Hired" do not have scorecard template
    Placements::ChangeStage.new(
      placement: ruby_placement, new_stage: "Hired"
    ).call.value!

    get tab_ats_candidate_path(candidate, :scorecards)

    assert_response :success

    visible_stage_names = css_select("#placement-#{ruby_placement.id} .text-gray-600").map(&:text)

    assert_equal visible_stage_names, %w[Sourced Contacted Replied]
  end

  test "should not display placement in scorecards table if scorecard template associated with " \
       "stage later than placement stage" do
    sign_in accounts(:admin_account)

    ruby_placement = placements(:sam_ruby_contacted)
    replied_stage_scorecard_template = scorecard_templates(:ruby_position_replied_scorecard_template)
    candidate = candidates(:sam)

    assert_equal ruby_placement.position_id, replied_stage_scorecard_template.position_stage.position_id
    assert_equal ruby_placement.stage, "Contacted"
    assert_equal replied_stage_scorecard_template.position_stage.name, "Replied"

    scorecard_templates(:ruby_position_contacted_scorecard_template).destroy!
    scorecard_templates(:ruby_position_sourced_scorecard_template).destroy!

    get tab_ats_candidate_path(candidate, :scorecards)

    assert_response :success

    assert_empty css_select("#placement-#{ruby_placement.id}")
  end

  test "merge should transfer all files and associated events from duplicates " \
       "and take cv from the most recently active duplicate as current cv" do
    candidate = candidates(:john)
    duplicate1 = candidates(:john_duplicate)
    duplicate2 = candidates(:john_duplicate).dup
    duplicate_email_address = candidate_email_addresses(:john_email_address1)
    duplicate2.update!(emails: [duplicate_email_address.slice(:address, :type, :tenant)])

    assert_empty candidate.files
    assert_empty duplicate1.files
    assert_empty duplicate2.files
    assert_equal candidate.duplicates.sort, [duplicate1, duplicate2].sort

    cv1 = fixture_file_upload("empty.pdf", "application/pdf")
    cv2 = fixture_file_upload("cv_with_links.pdf", "application/pdf")
    assert_difference "Event.where(type: 'active_storage_attachment_added').count", 3 do
      assert_difference "Event.where(type: 'candidate_changed', changed_field: 'cv').count", 3 do
        post upload_cv_file_ats_candidate_path(candidate), params: { candidate: { file: cv1 } }
        post upload_cv_file_ats_candidate_path(duplicate1), params: { candidate: { file: cv2 } }
        post upload_cv_file_ats_candidate_path(duplicate2), params: { candidate: { file: cv1 } }
      end
    end

    file = fixture_file_upload("app/assets/images/icons/user.png", "image/png")
    assert_difference "Event.where(type: 'active_storage_attachment_added').count", 2 do
      post upload_file_ats_candidate_path(duplicate1), params: { candidate: { file: } }
      post upload_file_ats_candidate_path(duplicate2), params: { candidate: { file: } }
    end

    file_id_to_remove = duplicate2.files.find { _1.cv? == false }.id
    assert_difference "Event.where(type: 'active_storage_attachment_removed').count" do
      delete delete_file_ats_candidate_path(duplicate2), params: { candidate: { file_id_to_remove: } }
    end
    file_removed_event = Event.where(type: "active_storage_attachment_removed").last

    assert_equal file_removed_event.eventable, duplicate2

    assert candidate.cv
    assert_equal candidate.files.count, 1
    assert duplicate1.cv
    assert_equal duplicate1.files.count, 2
    assert duplicate2.cv
    assert_equal duplicate2.files.count, 1

    duplicate1.update!(last_activity_at: 1.year.ago)
    duplicate2.update!(last_activity_at: 2.years.ago)
    candidate.update!(last_activity_at: 3.years.ago)

    most_recent_cv_blob_id = duplicate1.cv.blob_id

    assert_no_difference ["ActiveStorage::Attachment.count", "AttachmentInformation.count"] do
      # TODO: replace with controller method call.
      ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
      Candidates::Merge.new(
        target: candidate,
        actor_account_id: accounts(:admin_account).id
      ).call.value!
    end

    assert_equal candidate.files.count, 4
    assert_equal candidate.files.attachments.count(&:attachment_information), 3
    assert_equal candidate.cv.blob_id, most_recent_cv_blob_id
    assert_empty duplicate1.reload.files
    assert_empty duplicate2.reload.files
  end

  test "should delete a candidate" do
    sign_out

    account = accounts(:admin_account)
    candidate = candidates(:john)

    assert_equal candidate.tenant_id, account.tenant_id

    sign_in account
    assert_difference "Candidate.count", -1 do
      delete ats_candidate_path(candidate)
    end

    assert_redirected_to ats_candidates_path
    assert_equal flash[:notice], I18n.t("candidates.candidate_deleted")
  end

  test "should display assigned and unassigned activities" do
    # for some reason signed in account is not the same as the current account when we run all tests.
    sign_out
    sign_in @current_account

    candidate = candidates(:jane)

    assert_nil candidate.recruiter_id
    assert_equal @current_account.name, "Adrian Barton"

    assert_difference "Event.where(type: :candidate_recruiter_assigned).count" do
      patch assign_recruiter_ats_candidate_path(candidate),
            params: { candidate: { recruiter_id: @current_account.member.id } }
    end

    assert_difference(
      "Event.where(type: %i[candidate_recruiter_assigned candidate_recruiter_unassigned]).count", 2
    ) do
      patch assign_recruiter_ats_candidate_path(candidate),
            params: { candidate: { recruiter_id: members(:admin_member).id } }
    end

    get tab_ats_candidate_url(candidate, :activities)

    activities =
      Nokogiri::HTML(response.body)
              .css("#activities div")
              .map { _1.at_css(":nth-child(2)").text.strip }

    reference_activities = [
      "Adrian Barton assigned themselves as recruiter to the candidate",
      "Adrian Barton unassigned themselves as recruiter from the candidate",
      "Adrian Barton assigned Admin Admin as recruiter to the candidate"
    ]

    assert_empty(reference_activities - activities)
  end

  test "should fetch positions" do
    candidate = candidates(:john)
    positions = [positions(:ruby_position), positions(:golang_position)]

    get ats_candidate_fetch_positions_path(candidate, q: "dev")

    assert_response :success

    options = Nokogiri::HTML(response.body).css("option").map { _1.text.strip }

    assert_equal options.sort, positions.map(&:name).sort
  end
end
