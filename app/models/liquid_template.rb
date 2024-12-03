# frozen_string_literal: true

class LiquidTemplate
  EMAIL_TEMPLATE_VARIABLE_NAMES =
    %w[first_name full_name sender_first_name sender_full_name company position].freeze

  def self.extract_attributes_from(current_member:, candidate:, position:)
    {
      "first_name" => candidate.full_name.split.first,
      "full_name" => candidate.full_name,
      "sender_first_name" => current_member.name.split.first,
      "sender_full_name" => current_member.name,
      "company" => current_member.tenant.name,
      "position" => position.name
    }
  end

  def initialize(body, type: nil)
    # `to_str` is used to convert classes such as ActionView::OutputBuffer to String.
    # ActionText#to_s produces an object of class ActionView::OutputBuffer.
    @template = Liquid::Template.parse(body.to_s.to_str, error_mode: :warn)
    @allowed_variables =
      case type
      when :email_template
        EMAIL_TEMPLATE_VARIABLE_NAMES
      else
        []
      end
  rescue Liquid::SyntaxError => e
    @syntax_error = e.message
  end

  def warnings
    return [@syntax_error] if @syntax_error.present?

    error_messages = []
    error_messages += @template.warnings if @template.warnings.present?

    invalid_variables = present_variables - @allowed_variables
    if invalid_variables.present?
      error_messages << <<~TEXT
        contains unknown variable #{'name'.pluralize(invalid_variables.size)}
        #{invalid_variables.map { "\"#{_1}\"" }.to_sentence(last_word_connector: ' and ')}.
      TEXT
    end

    error_messages
  end

  def present_variables
    Liquid::ParseTreeVisitor
      .for(@template.root)
      .add_callback_for(Liquid::VariableLookup) do |node|
      [node.name, *node.lookups].join(".")
    end.visit.flatten.uniq.compact
  end

  def missing_variables
    @missing_variables || []
  end

  def render(attributes)
    @missing_variables = present_variables - attributes.keys
    @template.render(attributes)
  end
end
