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
end
