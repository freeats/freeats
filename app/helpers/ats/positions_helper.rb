# frozen_string_literal: true

module ATS::PositionsHelper
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
end
