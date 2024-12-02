# frozen_string_literal: true

class ButtonLinkComponent < ButtonComponent
  param :href, Types::Strict::String
  option :target, Types::Symbol.enum(:_self, :_blank, :_parent, :_top), optional: true
  option :type, optional: true

  def call
    link_content =
      link_to(
        href,
        class: [
          DEFAULT_CLASSES,
          variant_class,
          size_class,
          disabled_class,
          hidden_class,
          flex_content_position_class,
          additional_options.delete(:class)
        ],
        target:,
        type:,
        **additional_options
      ) do
        safe_join([icon, content])
      end

    if tooltip_title
      tag.span(class: "d-inline-block", data: { bs_toggle: :tooltip }, title: tooltip_title) do
        link_content
      end
    else
      link_content
    end
  end
end
