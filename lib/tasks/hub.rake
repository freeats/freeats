# frozen_string_literal: true

# TODO: remove this task.
namespace :hub do
  task :export_candidates, %i[position_id] => :environment do |_task, args|
    tenant = Tenant.find_by!(name: "Toughbyte")
    ActsAsTenant.with_tenant(tenant) do
      position = Position.find(args[:position_id])
      stages = position.stages.to_a
      CSV.parse(Rails.root.join("lib/tasks/candidates.csv").read, headers: true)
         .each do |row|
        next if Candidate.find_by(external_source_id: row["id"].delete(" "))

        ActiveRecord::Base.transaction do
          if row["person_source"].present?
            source = CandidateSource.find_or_create_by!(name: row["person_source"])
          end
          candidate = Candidate.create!(
            full_name: row["name"],
            company: row["company"] || "",
            headline: row["headline"] || "",
            blacklisted: row["handsoff"],
            candidate_source: source,
            telegram: row["telegram"] || "",
            skype: row["skype"] || "",
            location_id: row["location_id"]&.delete(" ").presence,
            external_source_id: row["id"].delete(" ")
          )
          if row["name_ru"].present?
            CandidateAlternativeName.create!(name: row["name_ru"], candidate:)
          end
          stage = position.stages.find_by!(name: row["stage"].humanize)
          placement = Placement.create!(
            position:,
            candidate:,
            position_stage: stage,
            status: Placement.statuses[row["status"]] || "other"
          )
          row["emails"].delete("{|}").split(",").uniq.each_with_index do |email, index|
            next if email.blank? || email == "NULL"

            CandidateEmailAddress.create!(
              list_index: index + 1, address: email, candidate:, type: :personal
            )
          end
          row["phones"].delete("{|}").split(",").uniq.each_with_index do |phone, index|
            next if phone.blank? || phone == "NULL"

            CandidatePhone.create!(list_index: index + 1, phone:, candidate:, type: :personal)
          end
          row["links"].delete("{|}").split(",").uniq.each do |link|
            next if link.blank? || link == "NULL"

            CandidateLink.create!(url: link, candidate:)
          end
          Event.create!(
            eventable: candidate,
            type: :candidate_added
          )
          if candidate.emails.present?
            Event.create!(
              type: :candidate_changed,
              eventable: candidate,
              changed_field: "email_addresses",
              changed_from: [],
              changed_to: candidate.emails
            )
          end
          if candidate.phones.present?
            Event.create!(
              type: :candidate_changed,
              eventable: candidate,
              changed_field: "phones",
              changed_to: candidate.phones,
              changed_from: []
            )
          end
          if candidate.links.present?
            Event.create!(
              type: :candidate_changed,
              eventable: candidate,
              changed_field: "links",
              changed_from: [],
              changed_to: candidate.links
            )
          end
          if candidate.source.present?
            Event.create!(
              type: :candidate_changed,
              eventable: candidate,
              changed_field: "candidate_source",
              changed_to: candidate.source
            )
          end
          if candidate.company.present?
            Event.create!(
              type: :candidate_changed,
              eventable: candidate,
              changed_field: "company",
              changed_to: candidate.company
            )
          end
          if candidate.headline.present?
            Event.create!(
              type: :candidate_changed,
              eventable: candidate,
              changed_field: "headline",
              changed_to: candidate.headline
            )
          end
          Event.create!(
            type: :candidate_changed,
            eventable: candidate,
            changed_field: "full_name",
            changed_to: candidate.full_name
          )
          if row["avatar"].present?
            url = row["avatar"].split(".")
            url[url.size - 1] = "jpg"
            AttachAvatarFromHuntflowJob.perform_later(
              candidate_id: candidate.id,
              avatar_url: url.join(".")
            )
          end
          stages.from(1).each do |st|
            break if st.id == stage.id

            Event.create!(
              type: :placement_changed,
              eventable: placement,
              changed_field: :stage,
              changed_from: stages[st.list_index - 2].id,
              changed_to: st.id
            )
          end
          Event.create!(
            type: :placement_added,
            eventable: placement
          )
          if placement.status != "qualified"
            Event.create!(
              type: :placement_changed,
              eventable: placement,
              changed_field: :status,
              changed_from: "qualified",
              changed_to: placement.status
            )
          end
          cover_letter = row["body"].presence || ""
          unless row["salary"].to_i.zero?
            cover_letter =
              ["<i>Salary</i>: #{row['salary']} #{row['currency']}",
               cover_letter].join("</br></br>")
          end
          candidate.update!(cover_letter:) if cover_letter.present?
        end
      end
    end
  end

  task export_notes: :environment do
    tenant = Tenant.find_by!(name: "Toughbyte")
    ActsAsTenant.with_tenant(tenant) do
      note_thread_id = ""
      CSV.parse(Rails.root.join("lib/tasks/notes.csv").read, headers: true)
         .each do |row|
        candidate = Candidate.find_by(external_source_id: row["candidate_id"].delete(" "))
        account = Account.find_by(name: row["name"])
        unless account
          account = Account.create!(
            email: row["email"],
            name: row["name"],
            password_hash: RodauthApp.rodauth.allocate.password_hash("password"),
            status: "verified"
          )
          Member.create!(account:, access_level: :member)
        end
        if note_thread_id == row["note_thread_id"]
          note_thread = candidate.note_threads.last
        else
          note_thread =
            NoteThread.create!(
              notable: candidate,
              hidden: row["hidden"],
              created_at: row["created_at"]
            )
          note_thread_id = row["note_thread_id"]
          if note_thread.hidden?
            row["array_agg"].delete("{|}").split(",").uniq.each do |user|
              next if user.blank? || user == "NULL"

              member = Account.find_by(name: user)&.member
              next unless member

              note_thread.members << member
            end
            note_thread.save!
          end
        end
        note = Note.create!(
          note_thread:,
          text: row["text"],
          member: account.member,
          created_at: row["created_at"]
        )

        Event.create!(
          type: :note_added,
          eventable: note,
          actor_account: account,
          performed_at: row["created_at"]
        )
      end
    end
  end
end
