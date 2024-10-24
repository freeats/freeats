# frozen_string_literal: true

require "test_helper"

class Candidates::MergeTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    @candidate = candidates(:john)
    @candidate_duplicate = candidates(:john_duplicate)
    @actor_account = accounts(:admin_account)
    @member = members(:employee_member)

    @candidate_duplicate.update!(blacklisted: false)

    assert_equal @candidate.not_merged_duplicates, [@candidate_duplicate]
  end

  test "should fail with 'no_duplicates' when no duplicates exist" do
    result = Candidates::Merge.new(
      target: candidates(:sam),
      actor_account_id: @actor_account.id
    ).call

    assert_equal result, Failure(:no_duplicates)
  end

  test "should update 'merged_to' field and create 'candidate_merged event'" do
    assert_nil @candidate_duplicate.merged_to

    assert_difference "Event.count" => 1 do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!

      assert_equal @candidate_duplicate.reload.merged_to, @candidate.id

      event = Event.last

      assert_equal event.type, "candidate_merged"
      assert_equal event.eventable, @candidate_duplicate
      assert_equal event.actor_account, @actor_account
    end
  end

  test "should merge simple fields by taking the first non-default value " \
       "from target and duplicates" do
    simple_fields = {
      full_name: "John Doe",
      company: "Zalando",
      headline: "Ruby Developer",
      telegram: "@john_doe",
      skype: "john-doe"
    }

    @candidate.update!(simple_fields.slice(:full_name, :company))
    @candidate_duplicate.update!(simple_fields.slice(:headline, :telegram, :skype))

    simple_fields.slice(:headline, :telegram, :skype).each do |field, value|
      assert_not_equal @candidate.public_send(field), value
    end

    simple_fields.slice(:full_name, :company).each do |field, value|
      assert_not_equal @candidate_duplicate.public_send(field), value
    end

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    simple_fields.each do |field, value|
      assert_equal @candidate.public_send(field), value
    end
  end

  test "should take the newest last_activity_at from target and duplicates" do
    last_activity_at = 1.day.ago
    @candidate.update!(last_activity_at:)
    @candidate_duplicate.update!(last_activity_at: 1.week.ago)

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_in_delta @candidate.last_activity_at, last_activity_at
  end

  test "should blacklist candidate if one of the duplicates is blacklisted" do
    @candidate_duplicate.update!(blacklisted: true)

    assert_difference "Event.count" => 2 do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!

      events = Event.last(2)

      assert_equal events.pluck(:type), %w[candidate_changed candidate_merged]
      assert_equal events.first.changed_field, "blacklisted"
    end

    assert_predicate @candidate, :blacklisted?
  end

  test "should keep the candidate source if exists" do
    assert_nil @candidate.candidate_source
    assert_nil @candidate_duplicate.candidate_source

    candidate_source = candidate_sources(:linkedin)
    @candidate.update!(candidate_source:)

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.candidate_source, candidate_source
  end

  test "should take the first existing candidate source from duplicates " \
       "if target's one is blank" do
    assert_nil @candidate.candidate_source
    assert_nil @candidate_duplicate.candidate_source

    candidate_source = candidate_sources(:linkedin)
    @candidate_duplicate.update!(candidate_source:)

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.candidate_source, candidate_source
  end

  test "should take the first existing avatar from target and duplicates" do
    file = Rails.root.join("app/assets/images/icons/user.png").open
    @candidate_duplicate.avatar.attach(file)

    assert_not_predicate @candidate.avatar, :attached?
    assert_predicate @candidate_duplicate.avatar, :attached?

    blob_id = @candidate_duplicate.avatar.blob_id

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_predicate @candidate.avatar, :attached?
    assert_not_predicate @candidate_duplicate.reload.avatar, :attached?
    assert_equal @candidate.avatar.blob_id, blob_id
  end

  test "should transfer all files from duplicates" do
    file = Rails.root.join("test/fixtures/files/empty.pdf").open
    @candidate_duplicate.files.attach(file)

    assert_not_predicate @candidate.files, :attached?
    assert_predicate @candidate_duplicate.files, :attached?

    blob_ids = @candidate_duplicate.files.blobs.ids

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_predicate @candidate.files, :attached?
    assert_not_predicate @candidate_duplicate.reload.files, :attached?
    assert_equal @candidate.files.blobs.ids.sort, blob_ids.sort
  end

  test "should transfer cv from duplicates during merge and create event if target has no cv" do
    file = Rails.root.join("test/fixtures/files/empty.pdf").open
    @candidate_duplicate.files.attach(file)
    AttachmentInformations::Add.new(
      params: { active_storage_attachment_id: @candidate_duplicate.files.first.id, is_cv: true }
    ).call.value!

    assert @candidate_duplicate.cv
    assert_empty @candidate.files

    assert_difference "Event.where(type: 'candidate_changed', changed_field: 'cv').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: accounts(:admin_account).id
      ).call.value!
    end

    event = Event.where(type: "candidate_changed", changed_field: "cv").last

    assert_equal event.eventable, @candidate
    assert_equal event.changed_from, ""
    assert_equal event.changed_to, "empty.pdf"

    assert @candidate.cv
    assert_empty @candidate_duplicate.reload.files
  end

  test "should find the most relevant location from target and duplicates" do
    @candidate.update!(location: locations(:finland_country))
    @candidate_duplicate.update!(location: locations(:helsinki_city))

    assert_difference "Event.count" => 2 do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!

      assert_equal @candidate.reload.location, @candidate_duplicate.location

      events = Event.last(2)

      assert_equal events.pluck(:type), %w[candidate_changed candidate_merged]

      assert_equal events.first.changed_field, "location"
      assert_equal events.first.changed_from, locations(:finland_country).short_name
      assert_equal events.first.changed_to, locations(:helsinki_city).short_name
    end
  end

  test "should set new recruiter if specified" do
    assert_equal @candidate.recruiter, members(:admin_member)
    assert_nil @candidate_duplicate.recruiter

    assert_difference "Event.count" => 3 do
      Candidates::Merge.new(
        target: @candidate,
        new_recruiter_id: members(:employee_member).id,
        actor_account_id: @actor_account.id
      ).call.value!

      assert_equal @candidate.recruiter, members(:employee_member)

      events = Event.last(3)

      assert_equal events.pluck(:type),
                   %w[candidate_recruiter_unassigned
                      candidate_recruiter_assigned
                      candidate_merged]

      assert_equal events.first.reload.changed_from, members(:admin_member).id
      assert_equal events.second.reload.changed_to, members(:employee_member).id
    end
  end

  test "should keep current recruiter if exists and new recruiter is not specified" do
    assert_equal @candidate.recruiter, members(:admin_member)
    @candidate_duplicate.update!(recruiter: members(:employee_member))

    assert_no_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!

      assert_equal @candidate.recruiter, members(:admin_member)
    end
  end

  test "should merge and refresh different email addresses" do
    old_email = [{
      address: "old@email.com",
      source: "linkedin",
      status: "invalid",
      list_index: 1,
      type: "personal"
    }]
    new_email = [{
      address: "new@email.com",
      source: "github",
      status: "current",
      list_index: 1,
      type: "personal"
    }]
    @candidate.candidate_email_addresses.destroy_all
    @candidate_duplicate.candidate_email_addresses.destroy_all
    @candidate.update!(candidate_email_addresses_attributes: old_email)
    @candidate_duplicate.update!(candidate_email_addresses_attributes: new_email)

    assert_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.reload.candidate_email_addresses.pluck(:address, :status, :source).sort,
                 (old_email + new_email).pluck(:address, :status, :source).sort
  end

  test "should merge and refresh the same email addresses" do
    old_email = [{
      address: "old@email.com",
      source: "linkedin",
      status: "invalid",
      list_index: 1,
      type: "personal"
    }]
    same_email = [{
      address: "old@email.com",
      source: "github",
      status: "current",
      list_index: 1,
      type: "personal"
    }]

    @candidate.candidate_email_addresses.destroy_all
    @candidate_duplicate.candidate_email_addresses.destroy_all
    @candidate.update!(candidate_email_addresses_attributes: old_email)
    @candidate_duplicate.update!(candidate_email_addresses_attributes: same_email)

    assert_no_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.reload.candidate_email_addresses.pluck(:address, :source, :status),
                 old_email.pluck(:address, :source, :status)
  end

  test "should merge and refresh same email addresses with different sources" do
    email_with_source_other = [
      {
        address: "some@email.com",
        source: "other",
        status: "current",
        url: "",
        list_index: 1,
        type: "personal"
      }
    ]
    same_email_with_another_source = [
      {
        address: "some@email.com",
        source: "github",
        status: "current",
        url: "https://example.com",
        created_by_id: Member.order("random()").first.id,
        list_index: 1,
        type: "personal"
      }
    ]

    @candidate.candidate_email_addresses.destroy_all
    @candidate_duplicate.candidate_email_addresses.destroy_all
    @candidate.update!(candidate_email_addresses_attributes: email_with_source_other)
    @candidate_duplicate.update!(candidate_email_addresses_attributes: same_email_with_another_source)

    assert_no_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.candidate_email_addresses.pluck(:source, :url, :type, :created_by_id),
                 same_email_with_another_source.pluck(:source, :url, :type, :created_by_id)
  end

  test "should merge and refresh different candidate links" do
    old_link = [{
      url: "https://github.com/test_url",
      status: "outdated"
    }]
    new_link = [{
      url: "https://github.com/new_test_url",
      status: "current"
    }]

    @candidate.candidate_links.destroy_all
    @candidate_duplicate.candidate_links.destroy_all
    @candidate.update!(candidate_links_attributes: old_link)
    @candidate_duplicate.update!(candidate_links_attributes: new_link)

    assert_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.reload.candidate_links.pluck(:url, :status).sort,
                 (old_link + new_link).pluck(:url, :status).sort
  end

  test "should merge and refresh the same links" do
    old_link = [{
      url: "https://github.com/test_url",
      status: "outdated"
    }]
    same_link = [{
      url: "https://github.com/test_url",
      status: "current"
    }]

    @candidate.candidate_links.destroy_all
    @candidate_duplicate.candidate_links.destroy_all
    @candidate.update!(candidate_links_attributes: old_link)
    @candidate_duplicate.update!(candidate_links_attributes: same_link)

    assert_no_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.candidate_links.pluck(:url, :status),
                 old_link.pluck(:url, :status)
  end

  test "should merge and refresh different phones" do
    old_phone = [{
      phone: "+22222222222",
      source: "linkedin",
      status: "outdated",
      type: "personal",
      list_index: 1
    }]
    new_phone = [{
      phone: "+33333333333",
      source: "linkedin",
      status: "current",
      type: "personal",
      list_index: 1
    }]

    @candidate.candidate_phones.destroy_all
    @candidate.update!(candidate_phones_attributes: old_phone)
    @candidate_duplicate.update!(candidate_phones_attributes: new_phone)

    assert_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.reload.candidate_phones.pluck(:phone, :status, :source).sort,
                 (old_phone + new_phone).pluck(:phone, :status, :source).sort
  end

  test "should merge and refresh the same phones" do
    old_phone = [{
      phone: "+12345678901",
      source: "linkedin",
      status: "outdated",
      type: "personal",
      list_index: 1
    }]
    same_phone = [{
      phone: "+12345678901",
      source: "linkedin",
      status: "current",
      type: "personal",
      list_index: 1
    }]

    @candidate.candidate_phones.destroy_all
    @candidate.update!(candidate_phones_attributes: old_phone)
    @candidate_duplicate.update!(candidate_phones_attributes: same_phone)

    assert_no_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.candidate_phones.pluck(:phone, :status, :source),
                 old_phone.pluck(:phone, :status, :source)
  end

  test "should merge the same phones with different sources" do
    phone_with_source_other = [{
      phone: "+12345678901",
      source: "other",
      status: "current",
      type: "personal",
      list_index: 1
    }]
    same_phone_with_source_github = [{
      phone: "+12345678901",
      source: "github",
      status: "current",
      type: "personal",
      list_index: 1
    }]

    @candidate.candidate_phones.destroy_all
    @candidate.update!(candidate_phones_attributes: phone_with_source_other)
    @candidate_duplicate.update!(candidate_phones_attributes: same_phone_with_source_github)

    assert_no_difference "Event.where(type: 'candidate_changed').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.candidate_phones.pluck(:phone, :status, :source, :type),
                 @candidate_duplicate.candidate_phones.pluck(:phone, :status, :source, :type)
  end

  test "should transfer all duplicates placements" do
    candidate_placements = @candidate.placements.to_a

    assert_not_empty candidate_placements
    assert_empty @candidate_duplicate.placements

    placement = create(
      :placement,
      candidate: @candidate_duplicate,
      position: positions(:golang_position),
      position_stage: position_stages(:golang_position_sourced)
    )

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.reload.placements.sort, [*candidate_placements, placement].sort
    assert_empty @candidate_duplicate.reload.placements
  end

  test "should transfer all duplicates tasks" do
    candidate_tasks = @candidate.tasks.to_a

    assert_not_empty candidate_tasks
    assert_empty @candidate_duplicate.tasks

    task = create(:task, taskable: @candidate_duplicate)

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        duplicates: [@candidate_duplicate],
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.reload.tasks.sort, [*candidate_tasks, task].sort
    assert_empty @candidate_duplicate.reload.tasks
  end

  test "should transfer all duplicates note threads" do
    assert_equal @candidate.note_threads, [note_threads(:thread_one), note_threads(:thread_two)]
    assert_empty @candidate_duplicate.note_threads

    note_thread = create(
      :note_thread,
      notable: @candidate_duplicate
    )

    note_removed_event = create(:event, type: "note_removed", eventable: @candidate_duplicate)

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal note_removed_event.reload.eventable, @candidate
    assert_equal @candidate.reload.note_threads.sort,
                 [note_threads(:thread_one), note_threads(:thread_two), note_thread].sort
    assert_empty @candidate_duplicate.reload.note_threads
  end

  test "should add unique alternative names with duplicates' full names" do
    assert_equal @candidate.candidate_alternative_names,
                 [candidate_alternative_names(:john_alt_name)]
    assert_empty @candidate_duplicate.candidate_alternative_names

    create(
      :candidate_alternative_name,
      candidate: @candidate_duplicate,
      name: "Jean"
    )

    assert_no_difference "Event.where.not(type: 'candidate_merged').count" do
      Candidates::Merge.new(
        target: @candidate,
        actor_account_id: @actor_account.id
      ).call.value!
    end

    assert_equal @candidate.reload.candidate_alternative_names.pluck(:name).sort,
                 ["Jean", "Jehan", "John Doe Duplicate"]
    assert_empty @candidate_duplicate.reload.candidate_alternative_names
  end
end
