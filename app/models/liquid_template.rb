# frozen_string_literal: true

class LiquidTemplate
  SEQUENCE_TEMPLATE_VARIABLE_NAMES =
    %w[female first_name sender_calendar_url sender_first_name sender_linkedin_url
       position source].freeze

  OPTIONAL_TEMPLATE_VARIABLE_NAMES = %w[source].freeze

  def self.extract_attributes_from(current_account:, position: nil, candidate: nil)
    attributes = {
      "female" => current_account.female,
      "sender_calendar_url" => current_account.calendar_url,
      "sender_first_name" => current_account.name.split.first,
      "sender_linkedin_url" => current_account.linkedin_url
    }

    attributes["position"] = position.name if position.present?

    if candidate.present?
      attributes["first_name"] = candidate.full_name.split.first
      attributes["source"] = candidate.source
    end

    attributes
  end

  def initialize(body)
    # `to_str` is used to convert classes such as ActionView::OutputBuffer to String.
    # ActionText#to_s produces an object of class ActionView::OutputBuffer.
    @template = Liquid::Template.parse(body.to_s.to_str, error_mode: :warn)
    @allowed_variables = SEQUENCE_TEMPLATE_VARIABLE_NAMES
  rescue Liquid::SyntaxError => e
    @syntax_error = e.message
  end

  def present_variables
    Liquid::ParseTreeVisitor.for(@template.root)
                            .add_callback_for(Liquid::VariableLookup) do |node|
      [node.name, *node.lookups].join(".")
    end.visit.flatten.uniq.compact
  end

  def render(attributes)
    @missing_variables = present_variables - attributes.keys - OPTIONAL_TEMPLATE_VARIABLE_NAMES
    @template.render(attributes)
  end
end
