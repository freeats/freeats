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
        if field == "status"
          reason =
            if event.properties["change_status_reason"].present? &&
               event.properties["change_status_reason"] != "other"
              Position::CHANGE_STATUS_REASON_LABELS[event.properties["change_status_reason"].to_sym]
            else
              event.properties["comment"]
            end

          <<~TEXT
            changed position status from <b>#{from.humanize}</b> to
            <b>#{to.humanize}</b>#{" with reason: #{reason}" if reason.present?}
          TEXT
        elsif to.present? && from.present?
          "changed #{field} from <b>#{from}</b> to <b>#{to}</b>"
        elsif to.present?
          "added #{field} <b>#{to}</b>"
        elsif from.present?
          "removed #{field} <b>#{from}</b>"
        end
      when *Position::ASSIGNED_EVENTS
        member = Member.includes(:account).find(to)

        <<~TEXT
          assigned #{event_actor_account_name_for_assignment(event:, member:)} \
          as #{detect_field_by_event_type(event.type)} to the position
        TEXT
      when *Position::UNASSIGNED_EVENTS
        member = Member.includes(:account).find(from)

        <<~TEXT
          unassigned #{event_actor_account_name_for_assignment(event:, member:)} \
          as #{detect_field_by_event_type(event.type)} from the position
        TEXT
      when "position_stage_added"
        "added stage <b>#{event.properties['name']}</b>"
      when "position_stage_changed"
        "changed stage from <b>#{from}</b> to <b>#{to}</b>"
      when "position_stage_removed"
        "removed stage <b>#{event.removed_stage.name}</b>"
      when "scorecard_template_added"
        scorecard_template = event.eventable
        "added scorecard template " \
          "#{link_to(scorecard_template.title, ats_scorecard_template_path(scorecard_template))}"
      when "scorecard_template_removed"
        "removed scorecard template from <b>#{event.eventable.name}</b> stage"
      when "scorecard_template_changed"
        scorecard_template = event.eventable
        "updated scorecard template " \
          "#{link_to(scorecard_template.title, ats_scorecard_template_path(scorecard_template))}"
      when "task_added"
        "created <b>#{event.eventable.name}</b> task"
      when "task_status_changed"
        "#{event.changed_to == 'open' ? 'reopened' : 'closed'} " \
        "<b>#{event.eventable.name}</b> task"
      when "task_changed"
        ats_task_changed_display_activity(event)
      end

    sanitize(text)
  end

  def ats_position_color_class_for_status(status)
    colors = {
      "open" => "code-green",
      "on_hold" => "code-blue",
      "closed" => "code-black"
    }
    colors[status]
  end

  def position_description_edit_value(position)
    position.description.presence ||
      <<~HTML
        <b>General description</b>
        <br><br>
        <b>Responsibilities</b>
        <ul><li> </li></ul>
        <b>Requirements</b>
        <ul><li>Must-have
        <ul><li> </li></ul>
        </li></ul>
        <ul><li>Nice-to-have
        <ul><li> </li></ul>
        </li></ul>
        <b>Interview process</b>
        <ul><li> </li></ul>
        <b>Team</b>
        <br><br>
        <b>Salary range</b>
      HTML
  end

  def position_html_status_circle(position, tooltip_placement: "top", icon_size: :small)
    tooltip_status_reason_text =
      ", #{change_status_reason_tooltip_text(position)}"
    event_type, event_performed_at =
      if position.draft? || !position.last_position_status_changed_event
        ["Added on", position.added_event.performed_at.to_fs(:date)]
      else
        ["Status changed on",
         position.last_position_status_changed_event.performed_at.to_fs(:date)]
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
      -3 => "code-gray",
      -1 => "code-green",
      3 => "code-blue",
      6 => "code-black"
    }
    tooltips = {
      -3 => "Draft",
      -1 => "Open",
      3 => "On hold#{tooltip_status_reason_text}",
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

    render(
      IconComponent.new(
        :user,
        icon_type: position.draft? ? :outline : :filled,
        class: [colors[color_code], "flex-shrink-0"],
        size: icon_size,
        data: {
          bs_toggle: :tooltip,
          bs_title: tooltip,
          bs_html: true,
          bs_boundary: :viewport,
          bs_placement: tooltip_placement
        }
      )
    )
  end

  private

  def change_status_reason_tooltip_text(position)
    Position::CHANGE_STATUS_REASON_LABELS[position.change_status_reason&.to_sym]&.downcase
  end

  def detect_field_by_event_type(type)
    case type
    when "position_collaborator_assigned", "position_collaborator_unassigned"
      "collaborator"
    when "position_hiring_manager_assigned", "position_hiring_manager_unassigned"
      "hiring manager"
    when "position_interviewer_assigned", "position_interviewer_unassigned"
      "interviewer"
    when "position_recruiter_assigned", "position_recruiter_unassigned"
      "recruiter"
    end
  end
end
