# frozen_string_literal: true

module CandidatesHelper
  def ats_candidate_duplicates_merge_association_select(form, form_field_name, options_for_select)
    options = options_for_select.map do |text, value|
      { text:, value: }
    end
    render SingleSelectComponent.new(
      form,
      method: form_field_name,
      required: true,
      local: { options: }
    )
  end

  def candidate_display_activity(event)
    actor_account_name = compose_actor_account_name(event)

    text =
      case event.type
      when "candidate_added"
        if event.properties["method"] == "manual"
          [actor_account_name, "added the candidate manually"]
        elsif event.properties["method"] == "api"
          [actor_account_name, "added the candidate using extension"]
        else
          [actor_account_name, "added the candidate"]
        end
      when "candidate_changed"
        to = event.changed_to
        from = event.changed_from
        field = event.changed_field.humanize(capitalize: false)
        activity_text =
          if to.is_a?(Array) && from.is_a?(Array)
            removed = from - to
            added = to - from
            message = [
              ("removed <b>#{removed.join(', ')}</b> " if removed.any?),
              ("added <b>#{added.join(', ')}</b> " if added.any?)
            ].compact.join(" and ")
            message << field.singularize.pluralize([removed, added].max_by(&:size).size)
          elsif from.in?([true, false]) && to.in?([true, false])
            "#{to ? 'added' : 'removed'} <b>Blacklisted</b> status"
          elsif to.present? && from.present?
            "changed #{field} from <b>#{from}</b> to <b>#{to}</b>"
          elsif to.present?
            "added <b>#{to}</b> #{field}"
          elsif from.present?
            "removed <b>#{from}</b> #{field}"
          end
        [actor_account_name, activity_text]
      when "candidate_recruiter_assigned"
        [
          actor_account_name,
          <<~TEXT
            assigned \
            #{event_actor_account_name_for_assignment(event:, member: event.assigned_member)} \
            as recruiter to the candidate
          TEXT
        ]
      when "candidate_recruiter_unassigned"
        [
          actor_account_name,
          <<~TEXT
            unassigned \
            #{event_actor_account_name_for_assignment(event:, member: event.unassigned_member)} \
            as recruiter from the candidate
          TEXT
        ]
      when "email_received"
        message = event.eventable
        activity_text =
          <<~TEXT
            The candidate #{message.in_reply_to.present? ? 'replied to' : 'sent'} the email <b>
            #{message.subject}</b> <blockquote class='activity-quote
            'text-truncate'>#{
            message.plain_body&.truncate(180)}</blockquote>
          TEXT
        [activity_text]
      when "email_sent"
        message = event.eventable
        [
          actor_account_name,
          <<~TEXT
            #{message.in_reply_to.present? ? 'replied to' : 'sent'}
            the email <b>#{message.subject}</b> <blockquote class='activity-quote
            text-truncate'>#{
            message.plain_body&.truncate(180)}</blockquote>
          TEXT
        ]
      when "active_storage_attachment_added"
        [actor_account_name, "added file <b>#{event.properties['name']}</b>"]
      when "active_storage_attachment_removed"
        [actor_account_name, "removed file <b>#{event.properties['name']}</b>"]
      when "note_added"
        [
          actor_account_name,
          "added a note <blockquote class='activity-quote text-truncate'>
          #{event.eventable&.text&.truncate(180)}</blockquote>"
        ]
      when "note_removed"
        [actor_account_name, "removed a note"]
      when "placement_added"
        position = event.eventable.position
        activity_text =
          if event.properties["applied"] == true
            "applied to #{link_to(position.name, ats_position_path(position))}"
          else
            "assigned the candidate to #{link_to(position.name, ats_position_path(position))}"
          end
        actor_text =
          if event.properties["applied"] == true
            ["Candidate"]
          else
            [actor_account_name]
          end
        [actor_text, activity_text]
      when "placement_changed"
        [actor_account_name, placement_changed_text(event)]
      when "placement_removed"
        position = Position.find(event.properties["position_id"])
        [actor_account_name,
         "unassigned the candidate from #{link_to(position.name, ats_position_path(position))}"]
      when "scorecard_added"
        scorecard = event.eventable
        position = scorecard.placement.position
        [
          actor_account_name,
          "added scorecard #{link_to(scorecard.title, ats_scorecard_path(scorecard))} " \
          "for #{link_to(position.name, ats_position_path(position))}"
        ]
      when "scorecard_removed"
        position = event.eventable.position
        [
          actor_account_name,
          "removed scorecard <b>#{event.changed_from}</b> " \
          "for #{link_to(position.name, ats_position_path(position))}"
        ]
      when "scorecard_changed"
        scorecard = event.eventable
        position = scorecard.placement.position
        [
          actor_account_name,
          "updated scorecard #{link_to(scorecard.title, ats_scorecard_path(scorecard))} " \
          "for #{link_to(position.name, ats_position_path(position))}"
        ]
      when "task_added"
        [actor_account_name, "created <b>#{event.eventable.name}</b> task"]
      when "task_status_changed"
        [
          actor_account_name,
          "#{event.changed_to == 'open' ? 'reopened' : 'closed'} " \
          "<b>#{event.eventable.name}</b> task"
        ]
      when "task_changed"
        [actor_account_name, ats_task_changed_display_activity(event)]
      else
        Log.tagged("candidate_display_activity") do |log|
          log.external_log("unhandled event type #{event.type}")
        end
        return
      end

    left_datetime_element = tag.span(class: "fw-light me-2") do
      event.performed_at.to_fs(:datetime)
    end
    right_event_info_element = tag.span(sanitize(text.join(" ")))

    tag.div(id: "event-#{event.id}") do
      safe_join([left_datetime_element, right_event_info_element])
    end
  end

  private

  def placement_changed_text(event)
    position = event.eventable.position
    position_link = link_to(position.name, ats_position_path(position))

    case event.changed_field
    when "status"
      case event.changed_to
      when "qualified"
        "requalified the candidate on #{position_link}"
      when "reserved"
        "reserved the candidate on #{position_link}"
      when "disqualified"
        <<~TEXT
          disqualified the candidate on #{position_link}
          with reason <b>#{event.properties['reason']}</b>
        TEXT
      end
    when "stage"
      stage = event.stage_to
      stage_name = stage.deleted ? "#{stage.name} (deleted)" : stage.name
      "moved the candidate to stage <b>#{stage_name}</b> on #{position_link}"
    end
  end
end
