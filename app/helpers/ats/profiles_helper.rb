# frozen_string_literal: true

module ATS::ProfilesHelper
  def ats_profile_button_tooltip_wrapper(tooltip:, **args, &)
    data = args[:data] || {}
    data = data.merge({ bs_toggle: "tooltip", bs_title: tooltip }) if tooltip.present?
    content_tag(
      :span,
      class: "d-inline-block",
      data:,
      **args.except(:data),
      &
    )
  end
end
