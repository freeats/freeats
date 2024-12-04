# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesGrid
  include Datagrid

  scope do
    EmailTemplate.order(updated_at: :desc)
  end

  column(:name, html: true, order: false, class: "w-100") do |model|
    link_to model.name, settings_recruitment_email_template_path(model.id)
  end

  column(:added) do |model|
    display_date(model.created_at)
  end

  column(:updated) do |model|
    display_date(model.updated_at)
  end

  def self.display_date(date)
    format(date.to_fs(:datetime_full)) do |value|
      tag.span(data: { bs_toggle: "tooltip", placement: "top" },
               title: value,
               class: "text-nowrap") do
        "#{short_time_ago_in_words(date)} ago"
      end
    end
  end

  private_class_method :display_date
end
