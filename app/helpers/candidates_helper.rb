# frozen_string_literal: true

module CandidatesHelper
  def candidates_compose_source_option_for_select(candidate_source, selected: true)
    {
      text: candidate_source.name,
      value: candidate_source.name,
      selected:
    }
  end

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

    text = [actor_account_name]

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
          assigned the candidate to
          #{event_actor_account_name_for_assignment(event:, member: event.assigned_member)}
        TEXT
      when "candidate_recruiter_unassigned"
        <<~TEXT
          unassigned
          #{event_actor_account_name_for_assignment(event:, member: event.unassigned_member)}
          from the candidate
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
        "assigned the candidate to #{link_to(position.name, tab_ats_position_url(position))}"
      when "placement_changed"
        placement_changed_text(event)
      when "placement_removed"
        position = Position.find(event.properties["position_id"])
        "unassigned the candidate from #{link_to(position.name, tab_ats_position_url(position))}"
      when "scorecard_added"
        "added scorecard <b>#{event.eventable.title}</b>"
      when "scorecard_updated"
        "updated scorecard <b>#{event.eventable.title}</b>"
      when "task_added"
        "created <b>#{event.eventable.name}</b> task"
      when "task_status_changed"
        "#{event.changed_to == 'open' ? 'reopened' : 'closed'} " \
        "<b>#{event.eventable.name}</b> task"
      when "task_changed"
        ats_task_changed_display_activity(event)
      when "candidate_interview_scheduled"
        "#{actor_account_name} appointed interview for " \
        "#{event.properties['scheduled_for'].to_datetime.in_time_zone.to_fs(:datetime)}"
      when "candidate_interview_resolved"
        scheduled_event = event.becomes(Candidate::Interview).pair_event
        scheduled =
          "scheduled for #{scheduled_event.scheduled_for.to_fs(:datetime)}"
        case event.properties["status"]
        when "passed"
          "#{actor_account_name} conducted interview #{scheduled} " \
          "and candidate <b>passed</b>"
        when "failed"
          "#{actor_account_name} conducted interview #{scheduled} " \
          "and candidate <b>failed</b>"
        when "canceled_by_candidate"
          "Candidate canceled interview with #{actor_account_name} #{scheduled}"
        when "canceled_by_recruiter"
          "#{actor_account_name} canceled interview #{scheduled}"
        when "missed_by_candidate"
          "Candidate missed interview with #{actor_account_name} #{scheduled}"
        when "canceled"
          "Interview with #{actor_account_name} #{scheduled} was canceled"
        else
          "Unknown status for interview, please contact support"
        end
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

    tag.li(class: "list-group-item", id: "event-#{event.id}") do
      safe_join([left_datetime_element, right_event_info_element])
    end
  end

  private

  def placement_changed_text(event)
    position = event.eventable.position
    position_link = link_to(position.name, tab_ats_position_url(position))

    case event.changed_field
    when "status"
      case event.changed_to
      when "qualified"
        "requalified the candidate on #{position_link}"
      when "reserved"
        "reserved the candidate on #{position_link}"
      else
        <<~TEXT
          disqualified the candidate on #{position_link}
          with reason <b>#{event.changed_to.humanize}</b>
        TEXT
      end
    when "stage"
      "moved the candidate to stage <b>#{event.stage_to.name}</b> on #{position_link}"
    end
  end
end
