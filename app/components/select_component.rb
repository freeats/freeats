# frozen_string_literal: true

# This component does not render anything on its own.
# It is used as a base class for other select components.

class SelectComponent < ApplicationComponent
  SIZE_CLASSES = {
    tiny: "tiny",
    small: "small",
    medium: "medium",
    large: "large"
  }.freeze

  BUTTON_GROUP_SIZE_CLASSES = {
    tiny: "btn-group-xs",
    small: "btn-group-sm",
    medium: "btn-group-md",
    large: "btn-group-md" # This is not a typo.
  }.freeze

  param :form_or_name, Types::Strict::String | Types::Instance(ActionView::Helpers::FormBuilder)
  option :size, Types::Symbol.enum(*SIZE_CLASSES.keys), default: -> { :small }
  option :readonly, Types::Strict::Bool, default: -> { false }
  option :disabled, Types::Strict::Bool.optional, default: -> { false }
  option :placeholder, Types::Strict::String, default: -> { "" }
  option :method, Types::Strict::String | Types::Strict::Symbol, optional: true

  option :local,
         Types::Strict::Hash.schema(
           options: Types::Strict::Array.of(
             Types::Strict::Hash.schema(
               text: Types::Strict::String,
               value: Types::Strict::Integer | Types::Strict::String | Types::Strict::Symbol,
               selected?: Types::Strict::Bool,
               disabled?: Types::Strict::Bool
             )
           )
         ),
         optional: true

  option :remote,
         Types::Strict::Hash.schema(
           search_url: Types::Strict::String,
           options?: Types::Strict::Array.of(
             Types::Strict::Hash.schema(
               text: Types::Strict::String,
               value: Types::Strict::Integer | Types::Strict::String | Types::Strict::Symbol,
               selected?: Types::Strict::Bool,
               disabled?: Types::Strict::Bool
             )
           ).optional
         ),
         optional: true

  def initialize(*args, **kwargs)
    if kwargs[:local] && kwargs[:remote]
      raise ArgumentError, "You can't pass both 'local' and 'remote' options."
    elsif kwargs[:local].nil? && kwargs[:remote].nil?
      raise ArgumentError, "You must pass at least 'local' or 'remote' option."
    elsif args.first.is_a?(ActionView::Helpers::FormBuilder) && kwargs[:method].nil?
      raise ArgumentError, "Method must be specified for using of a form."
    elsif !args.first.is_a?(ActionView::Helpers::FormBuilder) && kwargs[:method].present?
      raise ArgumentError, "Method must not be specified for using without form."
    end

    super(*args, **kwargs)
  end

  private

  def component_classes
    ["select-component", SIZE_CLASSES[size], ("with-chevron" if local)]
  end

  def compose_options_for_select
    return "" if local.nil? && remote[:options].nil?

    options = {}
    selected = []
    disabled = []

    (local || remote)[:options].each do |option|
      options[option[:text]] = option[:value]
      selected << option[:value] if option[:selected]
      disabled << option[:value] if option[:disabled]
    end

    options_for_select(options, selected:, disabled:)
  end
end
