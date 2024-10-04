# frozen_string_literal: true

namespace :huntflow do
  task :export_accounts, %i[tenant_id] => :environment do |_task, args|
    tenant = Tenant.find(args[:tenant_id])
    members = Huntflow::Coworker.index
    ActsAsTenant.with_tenant(tenant) do
      members.each do |member|
        find_or_create_account(
          email: member.email,
          name: member.name,
          external_source_id: member.user_id
        )
      end
    end
  end

  task :export_positions, %i[tenant_id] => :environment do |_task, args|
    logger = Logger.new($stdout)
    logger.info "Export jobs started."
    jobs = Huntflow::Position.index
    stages =
      Huntflow::PositionStage
      .index
      .filter { !_1.name.in?(%w[Backlog Отказ]) }
    stage_matching = {
      "New" => "Sourced",
      "Push" => "Replied"
    }
    tenant = Tenant.find(args[:tenant_id])
    ActsAsTenant.with_tenant(tenant) do
      jobs.each do |job|
        job.fetch_activities
        ActiveRecord::Base.transaction do
          position = Position.create!(
            name: job.name,
            external_source_id: job.id,
            status: job.status,
            change_status_reason: job.status == :active ? :new_position : :other
          )
          added_event = nil
          job.activities.sort_by(&:created).each do |act|
            case act.state
            when "CREATED"
              added_event = Event.create!(
                eventable: position,
                performed_at: act.created,
                type: :position_added,
                actor_account: find_or_create_account(
                  name: act.user.name,
                  external_source_id: act.user.id,
                  email: act.user.email
                )
              )
            when "OPEN"
              Event.create!(
                eventable: position,
                performed_at: act.created,
                changed_field: :status,
                changed_from: "draft",
                changed_to: "active",
                type: :position_changed,
                properties: {
                  change_status_reason: :new_position
                },
                actor_account: find_or_create_account(
                  name: act.user.name,
                  external_source_id: act.user.id,
                  email: act.user.email
                )
              )
            when "HOLD"
              Event.create!(
                eventable: position,
                performed_at: act.created,
                changed_field: :status,
                changed_from: "active",
                changed_to: "on_hold",
                type: :position_changed,
                properties: {
                  change_status_reason: :other,
                  comment: Huntflow::Position::HOLD_REASONS[act.hold_reason]
                },
                actor_account: find_or_create_account(
                  name: act.user.name,
                  external_source_id: act.user.id,
                  email: act.user.email
                )
              )
            when "RESUME"
              Event.create!(
                eventable: position,
                performed_at: act.created,
                changed_field: :status,
                changed_from: "on_hold",
                changed_to: "active",
                type: :position_changed,
                properties: {
                  change_status_reason: :other
                },
                actor_account: find_or_create_account(
                  name: act.user.name,
                  external_source_id: act.user.id,
                  email: act.user.email
                )
              )
            when "REOPEN"
              Event.create!(
                eventable: position,
                performed_at: act.created,
                changed_field: :status,
                changed_from: "closed",
                changed_to: "active",
                type: :position_changed,
                properties: {
                  change_status_reason: :other
                },
                actor_account: find_or_create_account(
                  name: act.user.name,
                  external_source_id: act.user.id,
                  email: act.user.email
                )
              )
            when "CLOSED"
              Event.create!(
                eventable: position,
                performed_at: act.created,
                changed_field: :status,
                changed_from: "active",
                changed_to: "closed",
                type: :position_changed,
                properties: {
                  change_status_reason: :other,
                  comment: Huntflow::Position::CLOSE_REASONS[act.close_reason]
                },
                actor_account: find_or_create_account(
                  name: act.user.name,
                  external_source_id: act.user.id,
                  email: act.user.email
                )
              )
            else
              logger.error "Unknown activity type #{act.state} for #{job.id} and name #{job.name}"
            end
          end
          Event.create!(
            eventable: position,
            performed_at: added_event.created_at + 1,
            type: :position_changed,
            changed_field: :name,
            changed_to: position.name,
            actor_account: added_event.actor_account
          )
          stages.each do |stage|
            pos_stage = PositionStage.create!(
              name: stage_matching[stage.name] || stage.name,
              external_source_id: stage.id,
              list_index: stage.order,
              deleted: stage.removed.present?,
              position:
            )
            Event.create!(
              eventable: pos_stage,
              type: :position_stage_added,
              properties: { name: pos_stage.name },
              performed_at: added_event.performed_at + stage.order + 1
            )
          end
        end
      rescue StandardError => e
        logger.error "Export job with id #{job.id} and name #{job.name} failed with #{e.inspect}"
      end
    end
    logger.info "Export jobs finished."
  end

  task :export_candidates, %i[tenant_id page] => :environment do |_task, args|
    logger = ATS::Logger.new(where: "candidate_export")
    tenant = Tenant.find(args[:tenant_id])
    page = args[:page] ? args[:page].to_i : 1
    logger.info "Export candidates on page #{page} started."
    candidates = Huntflow::Candidate.index(page)
    ActsAsTenant.with_tenant(tenant) do
      while candidates.size.positive?
        candidates.each do |hf_candidate|
          next if Candidate.find_by(external_source_id: hf_candidate.id)

          if hf_candidate.external_ids.present? && hf_candidate.external_ids.first[:account_source]
            source = CandidateSource.find_or_create_by!(
              name: Huntflow::Candidate::SOURCES[hf_candidate.external_ids.first[:account_source]]
            )
          end

          logger.info("huntflow id: #{hf_candidate.id}")
          hf_candidate.fetch_activities
          all_activities = hf_candidate.activities
          candidate_phones_attributes =
            if CandidatePhone.valid_phone?(hf_candidate.phone)
              [{ list_index: 1, phone: hf_candidate.phone, type: :personal }]
            else
              []
            end
          candidate_email_addresses_attributes =
            if hf_candidate.email.present?
              [{ list_index: 1, address: hf_candidate.email, type: :personal }]
            else
              []
            end
          ActiveRecord::Base.transaction do
            candidate = Candidate.create!(
              external_source_id: hf_candidate.id,
              full_name: hf_candidate.name,
              headline: hf_candidate.headline || "",
              company: hf_candidate.company || "",
              created_at: hf_candidate.created || Time.zone.now,
              last_activity_at: Time.zone.now,
              skype: hf_candidate.skype || "",
              candidate_email_addresses_attributes:,
              candidate_phones_attributes:,
              candidate_source: source
            )
            hf_candidate.placements.each do |placement|
              position = Position.find_by!(external_source_id: placement.position_id)
              placement_activities =
                hf_candidate.activities.filter { _1.position_id == placement.position_id }
              all_activities -= placement_activities
              placement_status =
                case placement.stage
                when Huntflow::PositionStage::BACKLOG_ID
                  :reserved
                when Huntflow::PositionStage::DISQUALIFY_ID
                  :other
                else
                  :qualified
                end
              pl = Placement.create!(
                external_source_id: placement.id,
                candidate:,
                position:,
                status: placement_status,
                position_stage: position.stages.find_by(external_source_id: placement.stage) ||
                  position.stages.first
              )
              placement_activities.each do |activity|
                actor_account = Account.find_by(
                  name: activity.account_info[:name]
                )
                case activity.type
                when "VACANCY-ADD"
                  Event.create!(
                    eventable: pl,
                    type: :placement_added,
                    performed_at: activity.created,
                    actor_account:
                  )
                when "STATUS"
                  case activity.status
                  when Huntflow::PositionStage::BACKLOG_ID
                    Event.create!(
                      eventable: pl,
                      type: :placement_changed,
                      changed_field: :status,
                      changed_to: :reserved,
                      changed_from: :qualified,
                      performed_at: activity.created,
                      actor_account:
                    )
                  when Huntflow::PositionStage::DISQUALIFY_ID
                    Event.create!(
                      eventable: pl,
                      type: :placement_changed,
                      changed_field: :status,
                      changed_to: Huntflow::PositionStage::REJECTION_REASONS_MATCHING[
                        activity.rejection_reason
                      ] || :other,
                      changed_from: :qualified,
                      performed_at: activity.created,
                      actor_account:
                    )
                  else
                    act_stage =
                      position.stages_including_deleted
                              .find_by(external_source_id: activity.status)
                    next if !act_stage || act_stage.list_index == 1

                    Event.create!(
                      eventable: pl,
                      type: :placement_changed,
                      changed_field: :stage,
                      changed_to: act_stage.id,
                      changed_from:
                        position.stages.find_by(list_index: act_stage.list_index - 1)&.id,
                      performed_at: activity.created,
                      actor_account:
                    )
                  end
                end
              end
            end
            all_activities.each do |activity|
              actor_account = Account.find_by(
                name: activity.account_info[:name]
              )
              case activity.type
              when "ADD"
                Event.create!(
                  eventable: candidate,
                  type: :candidate_added,
                  performed_at: activity.created,
                  actor_account:
                )
                if activity.comment&.starts_with?("https://")
                  CandidateLink.create!(candidate:, url: activity.comment)
                end
              when "COMMENT"
                if activity.email.present?
                  et = EmailThread.find_or_create_by!(
                    external_source_id: activity.email[:email_thread]
                  )
                  em = EmailMessage.create!(
                    email_thread_id: et.id,
                    message_id: activity.email[:foreign],
                    timestamp: Time.parse(activity.email[:created]).to_i,
                    html_body: activity.email[:html],
                    subject: activity.email[:subject],
                    in_reply_to: activity.email[:reply_to]&.first || ""
                  )
                  EmailMessageAddress.create!(
                    email_message: em,
                    field: "from",
                    address: activity.email[:from_email],
                    name: activity.email[:from_name] || "",
                    position: 1
                  )
                  activity.email[:to]&.each_with_index do |address, index|
                    next unless CandidateEmailAddress.valid_email?(address[:email])

                    EmailMessageAddress.create!(
                      email_message: em,
                      field: address[:type],
                      address: address[:email],
                      name: address[:displayName] || "",
                      position: index + 1
                    )
                  end
                  event_type =
                    if activity.email[:from_email].ends_with?("adbro.me")
                      :email_sent
                    else
                      :email_received
                    end
                  Event.create!(
                    actor_account: Account.find_by!(external_source_id: activity.account_info[:id]),
                    type: event_type,
                    eventable: em,
                    performed_at: activity.email[:created]
                  )
                elsif activity.comment.present?
                  account = Account.find_by!(external_source_id: activity.account_info[:id])
                  nt = NoteThread.create!(notable: candidate)
                  note =
                    Note.create!(
                      note_thread: nt,
                      text: activity.comment,
                      member_id: account.member.id
                    )
                  Event.create!(
                    type: :note_added,
                    eventable: note,
                    actor_account: account
                  )
                elsif activity.files.present?
                  activity.files.each do |info_hash|
                    AttachFileFromHuntflowJob.perform_later(
                      candidate_id: candidate.id,
                      info_hash:,
                      huntflow_actor_account_id: activity.account_info[:id],
                      file_added_at: activity.created
                    )
                  end
                end
              else
                logger.error "Unknown activity type #{activity.type} for #{
                  hf_candidate.id} and name #{hf_candidate.name}"
              end
            end
            if candidate.emails.present?
              Event.create!(
                type: :candidate_changed,
                eventable: candidate,
                performed_at: hf_candidate.created + 1,
                changed_field: "email_addresses",
                changed_from: [],
                changed_to: candidate.emails
              )
            end
            if candidate.phones.present?
              Event.create!(
                type: :candidate_changed,
                eventable: candidate,
                performed_at: hf_candidate.created + 2,
                changed_field: "phones",
                changed_to: candidate.phones,
                changed_from: []
              )
            end
            if candidate.links.present?
              Event.create!(
                type: :candidate_changed,
                eventable: candidate,
                performed_at: hf_candidate.created + 3,
                changed_field: "links",
                changed_from: [],
                changed_to: candidate.links
              )
            end
            if candidate.source.present?
              Event.create!(
                type: :candidate_changed,
                eventable: candidate,
                performed_at: hf_candidate.created + 4,
                changed_field: "candidate_source",
                changed_to: candidate.source
              )
            end
            if candidate.recruiter
              Event.create!(
                type: :candidate_recruiter_assigned,
                eventable: candidate,
                performed_at: hf_candidate.created + 4,
                changed_to: candidate.recruiter_id
              )
            end
            if candidate.company.present?
              Event.create!(
                type: :candidate_changed,
                eventable: candidate,
                performed_at: hf_candidate.created + 5,
                changed_field: "company",
                changed_to: candidate.company
              )
            end
            if candidate.headline.present?
              Event.create!(
                type: :candidate_changed,
                eventable: candidate,
                performed_at: hf_candidate.created + 6,
                changed_field: "headline",
                changed_to: candidate.headline
              )
            end
            Event.create!(
              type: :candidate_changed,
              eventable: candidate,
              performed_at: hf_candidate.created + 7,
              changed_field: "full_name",
              changed_to: candidate.full_name
            )
            if hf_candidate.photo_url.present?
              AttachAvatarFromHuntflowJob.perform_later(
                candidate_id: candidate.id,
                avatar_url: hf_candidate.photo_url
              )
            end
            hf_candidate.external_ids&.each do |info_hash|
              AttachResumeFromHuntflowJob.perform_later(
                candidate_id: candidate.id,
                hf_external_id: info_hash[:id]
              )
            end
          end
        rescue StandardError => e
          logger.error "Export candidate with id #{hf_candidate.id} on page #{page} failed with #{
            e.inspect}\n\n#{e.backtrace}"
        end
        page += 1
        candidates = Huntflow::Candidate.index(page)
      end
    end
  end

  # In Huntflow disqualification and the stage are stored as the status, so to detect
  # the stage on which candidate was disqualified/reserved need to check the last activity
  task :postprocess_placements, %i[tenant_id] => :environment do |_task, args|
    logger = Logger.new($stdout)
    logger.info "Postprocess started."
    tenant = Tenant.find(args[:tenant_id])
    ActsAsTenant.with_tenant(tenant) do
      Placement.where.not(status: :qualified).includes(:events).find_each do |placement|
        evs = placement.events.to_a
        changed_stage =
          evs.filter { _1.changed_field == "stage" && !_1.stage_to.deleted }.max_by(&:performed_at)
        changed_status = evs.filter { _1.changed_field == "status" }.max_by(&:performed_at)
        placement.status = changed_status.changed_to
        placement.position_stage_id = changed_stage.changed_to if changed_stage
        placement.save!
      rescue StandardError => e
        logger.error "Update placement with id #{placement.id} failed with #{e.inspect}"
      end

      # Candidate.find_each do |candidate|
      #   candidate.files.first&.change_cv_status
      # end
    end
  end

  private

  def find_or_create_account(name:, external_source_id:, email:)
    account = Account.find_by(external_source_id:)
    return account if account

    ActiveRecord::Base.transaction do
      account = Account.create!(
        email:,
        name:,
        external_source_id:,
        password_hash: RodauthApp.rodauth.allocate.password_hash("password"),
        status: "verified"
      )
      Member.create!(account:, access_level: :member)
    end
    account
  end
end
