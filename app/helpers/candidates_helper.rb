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
    actor_name = event.actor_account.name

    text =
      case event.type
      when "candidate_added"
        "#{actor_name} added the candidate"
      when "candidate_changed"
        message = "#{actor_name} "
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
          #{actor_name} assigned the candidate \
          to #{event_actor_account_name_for_assignment(event:, member: event.assigned_member)}
        TEXT
      when "candidate_recruiter_unassigned"
        <<~TEXT
          #{actor_name} unassigned \
          #{event_actor_account_name_for_assignment(event:, member: event.assigned_member)} \
          from the candidate
        TEXT
      end
    sanitize(text)
  end
end
