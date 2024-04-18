# frozen_string_literal: true

module ATS::PositionsHelper
  def ats_position_display_activity(event)
    actor_account_name = compose_actor_account_name(event)
    to = event.changed_to
    from = event.changed_from
    field = event.changed_field&.humanize(capitalize: false)

    text = "#{actor_account_name} "
    text <<
      case event.type
      when "position_added"
        "added the position"
      when "position_changed"
        if field.in?(["collaborators", "hiring managers", "interviewers"])
          assigned_and_unassigned_message(field, from, to)
        else
          from_and_to_message(field, from, to)
        end
      when "position_recruiter_assigned"
        <<~TEXT
          assigned the position \
          to #{event_actor_account_name_for_assignment(event:, member: event.assigned_member)}
        TEXT
      when "position_recruiter_unassigned"
        <<~TEXT
          unassigned \
          #{event_actor_account_name_for_assignment(event:, member: event.unassigned_member)} \
          from the position
        TEXT
      when "position_stage_added"
        "added stage <b>#{event.properties['name']}</b>"
      when "position_stage_changed"
        "changed stage from <b>#{from}</b> to <b>#{to}</b>"
      when "scorecard_template_added"
        "added scorecard <b>#{event.eventable.title}</b>"
      when "scorecard_template_updated"
        "updated scorecard <b>#{event.eventable.title}</b>"
      end

    sanitize(text)
  end

  def ats_position_color_class_for_status(status)
    colors = {
      "active" => "code-green",
      "passive" => "code-gray",
      "closed" => "code-black"
    }
    colors[status]
  end

  def position_description_edit_value(position)
    position.description.presence ||
      <<~HTML
        <b>Tasks:</b>
        <ul><li> </li></ul>
        <b>Must-have:</b>
        <ul><li> </li></ul>
        <b>Nice-to-have:</b>
        <ul><li> </li></ul>
        <b>Benefits and conditions:</b>
        <ul><li>Trial period:</li></ul>
        <b>Interview process:</b>
        <ul><li> </li></ul>
      HTML
  end

  def position_html_status_circle(position, tooltip_placement: "top")
    # TODO: use commented code if events have been added.
    tooltip_status_reason_text =
      ", #{change_status_reason_tooltip_text(position)}"
    event_type, event_performed_at =
      if position.draft? # || !position.last_position_status_changed_event
        # ["Added on", position.added_event.performed_at.to_fs(:date)]
        ["Added on", position.created_at.to_fs(:date)]
      else
        # ["Status changed on",
        # position.last_position_status_changed_event.performed_at.to_fs(:date)]
        ["Status changed on", position.updated_at.to_fs(:date)]
      end
    color_code =
      if position.respond_to?(:color_code)
        position.color_code
      else
        Position.with_color_codes.find(position.id).color_code
      end
    tooltip_code = color_code
    color_code = -1 if (0..2).cover?(color_code)
    colors = {
      -3 => "code-black",
      -1 => "code-green",
      3 => "code-gray",
      6 => "code-black"
    }
    tooltips = {
      -3 => "Draft",
      -1 => "Active",
      3 => "Passive#{tooltip_status_reason_text}",
      6 => "Closed#{tooltip_status_reason_text}"
    }
    tooltip = controller.render_to_string(
      partial: "ats/positions/position_circle_info_tooltip",
      formats: %i[html],
      locals: {
        status: tooltips[tooltip_code],
        event_type:,
        event_performed_at:
      }
    )

    <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
      <i class="fa-fw fa-user #{colors[color_code]} #{position.draft? ? 'fal' : 'fas'}"
         data-bs-toggle="tooltip"
         data-bs-title='#{tooltip}'
         data-bs-html="true"
         data-bs-boundary="viewport"
         data-bs-placement="#{tooltip_placement}">
      </i>
    HTML
  end

  private

  def change_status_reason_tooltip_text(position)
    Position::CHANGE_STATUS_REASON_LABELS[position.change_status_reason&.to_sym]&.downcase
  end

  def assigned_and_unassigned_message(field, from, to)
    to = Member.joins(:account).where(id: to).pluck("accounts.name")
    from = Member.joins(:account).where(id: from).pluck("accounts.name")
    assigned = (to - from).join(", ")
    unassigned = (from - to).join(", ")

    if assigned.present? && unassigned.present?
      "assigned <b>#{assigned}</b> and unassigned <b>#{unassigned}</b> as #{field}"
    elsif assigned.present?
      "assigned <b>#{assigned}</b> as #{field}"
    elsif unassigned.present?
      "unassigned <b>#{unassigned}</b> as #{field}"
    end
  end

  def from_and_to_message(field, from, to)
    if to.present? && from.present?
      "changed #{field} from <b>#{from}</b> to <b>#{to}</b>"
    elsif to.present?
      "added #{field} <b>#{to}</b>"
    elsif from.present?
      "removed #{field} <b>#{from}</b>"
    end
  end
end
