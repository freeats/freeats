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
      if event.type == "email_received"
        []
      else
        [actor_account_name]
      end
    text <<
      case event.type
      when "candidate_added"
        "added the candidate"
      when "candidate_changed"
        to = event.changed_to
        from = event.changed_from
        field = event.changed_field.humanize(capitalize: false)
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
      when "candidate_recruiter_assigned"
        <<~TEXT
          assigned \
          #{event_actor_account_name_for_assignment(event:, member: event.assigned_member)} \
          as recruiter to the candidate
        TEXT
      when "candidate_recruiter_unassigned"
        <<~TEXT
          unassigned \
          #{event_actor_account_name_for_assignment(event:, member: event.unassigned_member)} \
          as recruiter from the candidate
        TEXT
      when "email_received"
        message = event.eventable
        <<~TEXT
          The candidate #{message.in_reply_to.present? ? 'replied to' : 'sent'} the email <b>
          #{message.subject}</b> <blockquote class='activity-quote
          'text-truncate'>#{
          message.plain_body&.truncate(180)}</blockquote>
        TEXT
      when "email_sent"
        message = event.eventable
        <<~TEXT
          #{message.in_reply_to.present? ? 'replied to' : 'sent'}
          the email <b>#{message.subject}</b> <blockquote class='activity-quote
          text-truncate'>#{
          message.plain_body&.truncate(180)}</blockquote>
        TEXT
      when "active_storage_attachment_added"
        "added file <b>#{event.properties['name']}</b>"
      when "active_storage_attachment_removed"
        "removed file <b>#{event.properties['name']}</b>"
      when "note_added"
        "added a note <blockquote class='activity-quote text-truncate'>
        #{event.eventable&.text&.truncate(180)}</blockquote>"
      when "note_removed"
        "removed a note"
      when "placement_added"
        position = event.eventable.position
        "assigned the candidate to #{link_to(position.name, ats_position_path(position))}"
      when "placement_changed"
        placement_changed_text(event)
      when "placement_removed"
        position = Position.find(event.properties["position_id"])
        "unassigned the candidate from #{link_to(position.name, ats_position_path(position))}"
      when "scorecard_added"
        scorecard = event.eventable
        position = scorecard.placement.position
        "added scorecard #{link_to(scorecard.title, ats_scorecard_path(scorecard))} " \
          "for #{link_to(position.name, ats_position_path(position))}"
      when "scorecard_removed"
        position = event.eventable.position
        "removed scorecard <b>#{event.changed_from}</b> " \
          "for #{link_to(position.name, ats_position_path(position))}"
      when "scorecard_changed"
        scorecard = event.eventable
        position = scorecard.placement.position
        "updated scorecard #{link_to(scorecard.title, ats_scorecard_path(scorecard))} " \
          "for #{link_to(position.name, ats_position_path(position))}"
      when "task_added"
        "created <b>#{event.eventable.name}</b> task"
      when "task_status_changed"
        "#{event.changed_to == 'open' ? 'reopened' : 'closed'} " \
        "<b>#{event.eventable.name}</b> task"
      when "task_changed"
        ats_task_changed_display_activity(event)
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
