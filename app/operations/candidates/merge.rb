# frozen_string_literal: true

class Candidates::Merge < ApplicationOperation
  include Dry::Monads[:result]

  # target is used to perform the merge on a list of candidates: target + duplicates.
  option :target, Types::Instance(Candidate)

  # actor_account_id is the one who performed the merge.
  option :actor_account_id, Types::Strict::Integer

  # new_recruiter_id is the one who will be assigned as the candidates's new responsible member.
  # It is usually manually chosen by the actor account.
  option :new_recruiter_id, Types::Coercible::Integer.optional, optional: true

  AL = ActionList

  def call
    duplicates = target.not_merged_duplicates.to_a

    return Failure(:no_duplicates) if duplicates.empty?

    duplicates.sort_by!(&:last_activity_at)
    candidates = [target, *duplicates]

    target.with_lock do
      merge(target:, candidates:, duplicates:)
    end
  end

  private

  def merge(target:, candidates:, duplicates:)
    action_list = ActionList.new(
      target_candidate_id: target.id,
      actor_account_id:,
      logger:
    )

    # Simple fields
    action_list[:full_name] = merge_attribute_if_not_default(:full_name, target, candidates)
    action_list[:company] = merge_attribute_if_not_default(:company, target, candidates)
    action_list[:headline] = merge_attribute_if_not_default(:headline, target, candidates)
    action_list[:telegram] = merge_attribute_if_not_default(:telegram, target, candidates)
    action_list[:skype] = merge_attribute_if_not_default(:skype, target, candidates)

    action_list[:last_activity_at] = merge_last_activity_at(candidates)
    action_list[:blacklisted] = merge_blacklisted(duplicates)

    if action_list.changed?(:blacklisted)
      action_list << AL.fill_event(
        build_candidate_changed_event(
          changed_field: :blacklisted,
          changed_from: target.blacklisted,
          changed_to: action_list[:blacklisted]
        )
      )
    end

    action_list << merge_candidate_source(target, duplicates)

    action_list.add_field_and_records(
      :location_id,
      *merge_location(
        target_location: target.location,
        candidates_locations: candidates.map(&:location)
      )
    )

    action_list.add_field_and_records(
      :recruiter_id,
      *merge_responsible_member(
        target_responsible_member: target.recruiter,
        duplicates_responsible_members: duplicates.map(&:recruiter),
        new_recruiter_id:
      )
    )

    # Associations
    action_list << merge_candidate_email_addresses(
      target_id: target.id,
      target_email_addresses: target.candidate_email_addresses,
      duplicates_email_addresses: duplicates.map(&:candidate_email_addresses).flatten
    )

    action_list << merge_candidate_links(
      target_id: target.id,
      target_links: target.candidate_links,
      duplicates_candidate_links: duplicates.map(&:candidate_links).flatten
    )

    action_list << merge_candidate_phones(
      target_id: target.id,
      target_phones: target.candidate_phones,
      duplicates_candidate_phones: duplicates.map(&:candidate_phones).flatten
    )

    action_list << merge_placements(
      target_id: target.id,
      duplicates_placements: duplicates.map(&:placements).flatten
    )

    action_list << merge_tasks(
      target_id: target.id,
      duplicates_tasks: duplicates.map(&:tasks).flatten
    )

    action_list << merge_candidate_note_threads(
      target_id: target.id,
      duplicates_note_threads: duplicates.map(&:note_threads).flatten,
      duplicates_note_removed_events: duplicates
                                        .map { _1.events.where(type: %i[note_removed]) }
                                        .flatten
    )

    action_list << merge_candidate_alternative_names(
      target_id: target.id,
      tenant_id: target.tenant_id,
      target_candidate_alternative_names: target.candidate_alternative_names,
      duplicates_candidate_alternative_names: duplicates.map(&:candidate_alternative_names).flatten,
      duplicates_full_names: duplicates.map(&:full_name)
    )

    # Avatar
    action_list << merge_avatar(target, duplicates)

    # Files
    action_list << merge_files(target, duplicates)

    # Merge-related events
    duplicates.each do |duplicate|
      action_list << [
        AL.save_record(
          Event.new(
            type: :candidate_merged,
            properties: { merged_to: target.id },
            eventable_id: duplicate.id,
            eventable_type: "Candidate",
            actor_account_id:
          )
        )
      ]
    end

    target.assign_attributes(action_list.changeset)

    target.save!

    action_list.execute_actions

    if (persisted_duplicates = duplicates.filter(&:persisted?)).present?
      purge_duplicates(persisted_duplicates)

      # Here we don't want to save `duplicate` because it has associations in memory still
      # assigned to it, while in fact they were already transfered to the `target`.
      # rubocop:disable Rails/SkipsModelValidations
      Candidate.where(id: persisted_duplicates.map(&:id)).update_all(merged_to: target.id)
      # rubocop:enable Rails/SkipsModelValidations
    end

    Success(target:)
  end

  # Base merge logic
  def merge_attribute_if_not_default(field, target, candidates)
    @new_candidate ||= Candidate.new
    default_value = @new_candidate.public_send(field)

    new_value = candidates.filter_map do |candidate|
      value = candidate.public_send(field)
      value if value.present? && value != default_value
    end.first

    if new_value.nil? || target.public_send(field) == new_value
      AL::NONE
    else
      new_value
    end
  end

  def merge_last_activity_at(candidates)
    candidates.filter_map(&:last_activity_at).max
  end

  def merge_blacklisted(duplicates)
    return true if duplicates.find(&:blacklisted?)

    AL::NONE
  end

  def merge_candidate_source(target, duplicates)
    return AL::NONE if target.candidate_source

    candidate_source = duplicates.filter_map(&:candidate_source).first

    return AL::NONE unless candidate_source

    target.candidate_source_id = candidate_source.id
    AL.save_record(target)
  end

  def merge_avatar(target, duplicates)
    candidate = [target, *duplicates].find { _1.avatar.attached? }

    return AL::NONE unless candidate

    result = []

    target.avatar.attach(candidate.avatar.blob)
    result << AL.save_record(target)

    duplicates.each do |duplicate|
      duplicate.avatar.purge

      result << AL.save_record(duplicate)
    end

    result
  end

  def merge_files(target, duplicates)
    duplicates_ids = duplicates.map(&:id)
    duplicates_attachments =
      ActiveStorage::Attachment
      .joins("JOIN candidates ON active_storage_attachments.record_type = 'Candidate' " \
             "AND active_storage_attachments.record_id = candidates.id")
      .where(candidates: { id: duplicates_ids })
      .includes(:attachment_information)

    return AL::NONE if duplicates_attachments.blank?

    target_old_cv = target.cv

    most_recent_cv_data =
      Candidate
      .select("ai.id AS info_id, asb.id AS blob_id, asb.filename, asa.id AS attachment_id")
      .joins("JOIN active_storage_attachments AS asa ON asa.record_type = 'Candidate' " \
             "AND asa.record_id = candidates.id")
      .joins("JOIN attachment_informations AS ai ON ai.active_storage_attachment_id = asa.id")
      .joins("JOIN active_storage_blobs AS asb ON asa.blob_id = asb.id")
      .where(candidates: { id: [*duplicates_ids, target.id] })
      .where(ai: { is_cv: true })
      .order("candidates.last_activity_at DESC NULLS LAST")
      .first

    # Move attachments and associated events to the target.
    duplicates_attachments.each { _1.update!(record_id: target.id) }

    return AL::NONE if most_recent_cv_data.blank?

    result = []

    duplicates_attachments
      .reject { _1.id == most_recent_cv_data.attachment_id }
      .each do |attachment|
      attachment.attachment_information&.update!(is_cv: false)
    end

    if target_old_cv.present? && most_recent_cv_data.blob_id != target_old_cv.blob_id
      target_old_cv.attachment_information.update!(is_cv: false)
    elsif target_old_cv.blank?
      result << AL.fill_event(
        build_candidate_changed_event(
          changed_field: :cv,
          changed_from: "",
          changed_to: most_recent_cv_data.filename.to_s
        )
      )
    end

    result
  end

  def merge_candidate_email_addresses(
    target_id:,
    target_email_addresses:,
    duplicates_email_addresses:
  )
    result = []
    old_emails = target_email_addresses.to_a
    old_emails_addresses = old_emails.pluck(:address, :created_via)
    duplicate_emails =
      duplicates_email_addresses
      .filter { old_emails_addresses.include?([_1[:address], _1[:created_via]]) }
    new_emails = duplicates_email_addresses - duplicate_emails

    merge_email_attributes = lambda do |main_obj, update_obj|
      main_obj[:status] = update_obj[:status] if main_obj[:status] == "current"
      main_obj[:type] = update_obj[:type] if main_obj[:type].nil? && update_obj[:type].present?

      if main_obj[:source] == "other" && update_obj[:source] != "other"
        %i[source url created_by_id created_via].each do |field|
          main_obj[field] = update_obj[field]
        end
      end

      main_obj
    end

    old_emails.map! do |email|
      duplicate_email_with_same_address =
        duplicate_emails.find { _1[:address] == email[:address] }
      if duplicate_email_with_same_address
        merge_email_attributes.call(email, duplicate_email_with_same_address)
      else
        email
      end
    end

    email_addresses_array = (old_emails + new_emails).map(&:to_params)

    if new_emails.present?
      result << AL.fill_event(
        build_candidate_changed_event(
          changed_field: :email_addresses,
          changed_from: old_emails_addresses.map(&:first),
          changed_to: email_addresses_array.map { _1[:address] }
        )
      )
    end

    new_candidate_email_addresses = CandidateEmailAddress.combine(
      old_email_addresses: target_email_addresses.to_a,
      new_email_addresses: email_addresses_array,
      candidate_id: target_id
    )

    new_candidate_email_addresses.each do |new_email|
      result << AL.save_record(new_email)
    end

    result
  end

  def merge_candidate_links(target_id:, target_links:, duplicates_candidate_links:)
    result = []
    old_candidate_links = target_links.to_a
    old_candidate_links_url = old_candidate_links.map(&:url)
    duplicate_links =
      duplicates_candidate_links.filter { old_candidate_links_url.include?(_1[:url]) }
    new_candidate_links = duplicates_candidate_links - duplicate_links

    merge_link_attributes = lambda do |main_obj, update_obj|
      main_obj[:status] = update_obj[:status] if main_obj[:status] == "current"
      %i[created_by_id created_via].each do |field|
        main_obj[field] = update_obj[field]
      end
      main_obj
    end

    old_candidate_links.map! do |candidate_link|
      if (duplicate_link_with_same_link = duplicate_links.find { _1[:url] == candidate_link[:url] })
        merge_link_attributes.call(candidate_link, duplicate_link_with_same_link)
      else
        candidate_link
      end
    end

    candidate_links_array = (old_candidate_links + new_candidate_links).map(&:to_params)

    if new_candidate_links.present?
      result << AL.fill_event(
        build_candidate_changed_event(
          changed_field: :links,
          changed_from: old_candidate_links_url,
          changed_to: candidate_links_array.map { _1[:url] }
        )
      )
    end
    candidate_links = target_links

    new_candidate_links =
      candidate_links_array
      .sort_by { %w[current outdated].freeze.index(_1[:status]) }
      .filter { _1[:url].present? }
      .uniq { _1[:url] }

    existing_candidate_links_array =
      candidate_links.where(
        url: new_candidate_links.map { _1[:url] }
      ).to_a
    new_candidate_link_urls_array = []
    new_candidate_links.each do |attributes|
      existing_link_url =
        existing_candidate_links_array.find { _1.url == attributes[:url] }
      if existing_link_url
        existing_link_url.assign_attributes(attributes)
        result << AL.save_record(existing_link_url)
      else
        new_candidate_link_urls_array <<
          CandidateLink.new(
            attributes.merge(
              candidate_id: target_id
            )
          )
      end
    end

    new_candidate_link_urls_array.each do |new_candidate_link|
      result << AL.save_record(new_candidate_link)
    end

    result
  end

  def merge_candidate_phones(target_id:, target_phones:, duplicates_candidate_phones:)
    result = []
    old_candidate_phones = target_phones.to_a
    old_candidate_phones_numbers = old_candidate_phones.map(&:phone)
    duplicate_phones =
      duplicates_candidate_phones.filter { old_candidate_phones_numbers.include?(_1[:phone]) }
    new_candidate_phones = duplicates_candidate_phones - duplicate_phones

    merge_phone_attributes = lambda do |main_obj, update_obj|
      main_obj[:status] = update_obj[:status] if main_obj[:status] == "current"
      main_obj[:type] = update_obj[:type] if main_obj[:type].nil? && update_obj[:type].present?

      if main_obj[:source] == "other" && update_obj[:source] != "other"
        %i[source created_by_id created_via].each do |field|
          main_obj[field] = update_obj[field]
        end
      end

      main_obj
    end

    old_candidate_phones.map! do |phone|
      if (duplicate_phone_with_same_number = duplicate_phones.find { _1[:phone] == phone[:phone] })
        merge_phone_attributes.call(phone, duplicate_phone_with_same_number)
      else
        phone
      end
    end

    candidate_phones_array = (old_candidate_phones + new_candidate_phones).map(&:to_params)

    if new_candidate_phones.present?
      result << AL.fill_event(
        build_candidate_changed_event(
          changed_field: :phones,
          changed_from: old_candidate_phones_numbers,
          changed_to: candidate_phones_array.map { _1[:phone] }
        )
      )
    end

    candidate_phones = target_phones

    new_candidate_phones =
      candidate_phones_array
      .sort_by { %w[current outdated invalid].freeze.index(_1[:status]) }
      .filter { _1[:phone].present? }
      .uniq { _1[:phone] }

    existing_candidate_phones_array =
      candidate_phones.where(
        phone: new_candidate_phones.map { _1[:phone] }
      ).to_a

    new_candidate_phone_numbers_array = []
    new_candidate_phones.each.with_index(1) do |attributes, index|
      existing_phone_number =
        existing_candidate_phones_array.find { _1.phone == attributes[:phone] }
      if existing_phone_number
        attributes[:list_index] = index if existing_phone_number.list_index != index
        existing_phone_number.assign_attributes(attributes)
        result << AL.save_record(existing_phone_number)
      else
        new_candidate_phone_numbers_array <<
          CandidatePhone.new(
            attributes.merge(
              list_index: index,
              candidate_id: target_id
            )
          )
      end
    end
    new_candidate_phone_numbers_array.each do |new_candidate_phone|
      result << AL.save_record(new_candidate_phone)
    end

    result
  end

  def merge_candidate_alternative_names(
    target_id:,
    tenant_id:,
    target_candidate_alternative_names:,
    duplicates_candidate_alternative_names:,
    duplicates_full_names:
  )
    result = []

    new_alternative_names = (duplicates_candidate_alternative_names.pluck(:name) +
      duplicates_full_names -
      target_candidate_alternative_names.pluck(:name)).uniq

    return AL::NONE if new_alternative_names.empty?

    new_alternative_names.each do |name|
      alternative_name = CandidateAlternativeName.new(
        candidate_id: target_id,
        name:,
        tenant_id:
      )
      result << AL.save_record(alternative_name)
    end

    duplicates_candidate_alternative_names.each do |name|
      result << AL.destroy_record(name)
    end

    result
  end

  def merge_location(target_location:, candidates_locations:)
    result = []
    candidates_locations.compact!
    most_relevant_location = candidates_locations.first

    new_location =
      if most_relevant_location.present?
        candidates_locations.find { _1.child_of?(most_relevant_location) } || most_relevant_location
      end
    if new_location.present? && target_location&.id != new_location.id
      result << AL.fill_event(
        build_candidate_changed_event(
          changed_field: :location,
          changed_from: target_location&.short_name,
          changed_to: new_location&.short_name
        )
      )
      [new_location&.id, result]
    else
      AL::NONE
    end
  end

  def merge_responsible_member(
    target_responsible_member:,
    duplicates_responsible_members:,
    new_recruiter_id:
  )
    result = []
    new_responsible_member_id =
      new_recruiter_id || target_responsible_member&.id ||
      duplicates_responsible_members.compact.first&.id

    if target_responsible_member&.id != new_responsible_member_id
      if target_responsible_member.present?
        result << AL.fill_event(
          Event.new(
            type: :candidate_recruiter_unassigned,
            changed_from: target_responsible_member.id
          )
        )
      end
      result << AL.fill_event(
        Event.new(
          type: :candidate_recruiter_assigned,
          changed_to: new_responsible_member_id
        )
      )
    end

    [new_responsible_member_id, result]
  end

  def merge_placements(target_id:, duplicates_placements:)
    result = []
    duplicates_placements.each do |placement|
      placement.candidate_id = target_id
      result << AL.save_record(placement)
    end

    result
  end

  def merge_tasks(target_id:, duplicates_tasks:)
    result = []
    duplicates_tasks.each do |task|
      task.taskable_id = target_id
      result << AL.save_record(task)
    end

    result
  end

  def merge_candidate_note_threads(
    target_id:,
    duplicates_note_threads:,
    duplicates_note_removed_events:
  )
    result = duplicates_note_threads.map do |note_thread|
      AL.save_record(note_thread.tap { _1.notable_id = target_id })
    end
    duplicates_note_removed_events.each do |event|
      result << AL.save_record(event.tap { _1.eventable_id = target_id })
    end

    result
  end

  # Helpers
  def build_candidate_changed_event(changed_field:, changed_from:, changed_to:)
    Event.new(
      type: "candidate_changed",
      changed_field:,
      changed_from:,
      changed_to:
    )
  end

  def purge_duplicates(duplicates)
    # rubocop:disable Rails/SkipsModelValidations
    Candidate.where(id: duplicates.map(&:id)).update_all(recruiter_id: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
