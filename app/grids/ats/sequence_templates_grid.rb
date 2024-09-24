# frozen_string_literal: true

class ATS::SequenceTemplatesGrid
  include Datagrid

  scope { SequenceTemplate.not_archived }

  column(:name, html: true, order: false) do |model|
    link_to(model.name, ats_sequence_template_path(model))
  end

  column(:subject, order: false, &:subject)

  column(:updated, html: true, order: false) do |model|
    I18n.t("core.updated_time", time: short_time_ago_in_words(model.updated_at))
  end
end
