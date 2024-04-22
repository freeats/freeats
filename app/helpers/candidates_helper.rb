# frozen_string_literal: true

module CandidatesHelper
  def candidates_compose_source_option_for_select(candidate_source, selected: true)
    {
      text: candidate_source.name,
      value: candidate_source.name,
      selected:
    }
  end

  def candidate_display_activity(event)
    actor_account_name = compose_actor_account_name(event)

    text = "#{actor_account_name} "

    text <<
      case event.type
      when "candidate_added"
        "added the candidate"
      when "candidate_changed"
        # Otherwise the string is frozen and returns error upon calling <<
        message = +""
        to = event.changed_to
        from = event.changed_from
        field = event.changed_field
        if to.is_a?(Array) && from.is_a?(Array)
          removed = from - to
          added = to - from
          message << [
            ("removed <b>#{removed.join(', ')}</b> " if removed.any?),
            ("added <b>#{added.join(', ')}</b> " if added.any?)
          ].compact.join(" and ")
          message << field.singularize.pluralize([removed, added].max_by(&:size).size)
        elsif from.in?([true, false]) && to.in?([true, false])
          message << "#{to ? 'added' : 'removed'} <b>Don't contact</b> status"
        else
          message <<
          if to.present? && from.present?
            "changed #{field} from <b>#{from}</b> to <b>#{to}</b>"
          elsif to.present?
            "added <b>#{to}</b> #{field}"
          elsif from.present?
            "removed <b>#{from}</b> #{field}"
          end
        end
        message
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
      when "placement_added"
        position = event.eventable.position
        "assigned the candidate to #{link_to(position.name, tab_ats_position_url(position))}"
      when "placement_changed"
        placement_changed_text(event)
      when "scorecard_added"
        "added scorecard <b>#{event.eventable.title}</b>"
      when "scorecard_updated"
        "updated scorecard <b>#{event.eventable.title}</b>"
      end
    sanitize(text)
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
      "moved the candidate to stage <b>#{event.changed_to.humanize}</b> on #{position_link}"
    end
  end
end
