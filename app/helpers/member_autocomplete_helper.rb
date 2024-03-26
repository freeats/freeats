# frozen_string_literal: true

module MemberAutocompleteHelper
  def member_autocomplete_select_tag(name, options: {})
    options = options.dup
    options[:"data-reassignment-buttons-target"] = "input"
    options[:id] = "#{options.delete(:name)}#{'-mobile' if options.delete(:mobile)}"

    tag.div { select_tag(name, "", **options) }
  end
end
