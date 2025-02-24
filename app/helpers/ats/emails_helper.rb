# frozen_string_literal: true

module ATS::EmailsHelper
  def ats_pretty_email_addresses(email_addresses)
    email_addresses
      .map { |name, address| name.present? ? "#{name} <#{address}>" : address }.join(", ")
  end

  def ats_timelink_in_email_message(controller_name, email_message, possible_id, event_id)
    profile_activities_path =
      case controller_name
      when "candidates"
        tab_ats_candidate_path(possible_id, :activities, event: event_id)
      end
    link_to(t("core.created_time", time: short_time_ago_in_words(email_message.date)),
            profile_activities_path, data: { turbo: false })
  end

  def ats_compose_email_template_options(templates:)
    templates.map do |template|
      tag.option(value: template.id, label: template.name) do
        controller.render_to_string(
          partial: "ats/email_messages/email_template_element",
          locals: { template: }
        )
      end
    end.join
  end
end
