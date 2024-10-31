# frozen_string_literal: true

require "nokogiri"

# Original code from https://github.com/owaiswiz/tabler_icons_ruby
module TablerIcons
  class Error < StandardError; end

  def render_icon(
    icon_name,
    icon_type: "outline",
    size: nil,
    color: nil,
    class: nil,
    stroke_width: nil,
    **options
  )
    icon_name = icon_name.to_s.tr("_", "-")
    root = nokogiri_doc(icon_name, icon_type.to_s).root

    if size
      root.set_attribute("width", size)
      root.set_attribute("height", size)
    end

    if (html_class = binding.local_variable_get(:class))
      new_classes = html_class.is_a?(String) ? html_class.split : Array(html_class)
      classes = (root.classes + new_classes).join(" ")
      root.set_attribute("class", classes)
    end

    root.set_attribute("color", color) if color
    root.set_attribute("stroke-width", stroke_width) if stroke_width

    flatten_hash_options(options).each do |attribute_name, attribute_value|
      root.set_attribute(attribute_name, attribute_value)
    end

    html = root.to_html
    html = html.html_safe if html.respond_to?(:html_safe) # rubocop:disable Rails/OutputSafety
    html
  end

  private

  def flatten_hash_options(hash)
    hash.each_with_object({}) do |(key, value), acc|
      if value.is_a?(Hash)
        next flatten_hash_options(value).each do |k, v|
          acc["#{key}-#{k}".dasherize] = v
        end
      end
      acc[key] = value
    end
  end

  def nokogiri_doc(icon_name, icon_type)
    @icons_cache ||= {}
    @icons_cache[icon_name] ||= load_nokogiri_doc(icon_name, icon_type)
    @icons_cache[icon_name].dup
  rescue StandardError
    raise Error, "Could not find icon `#{icon_name}`."
  end

  def load_nokogiri_doc(icon_name, icon_type)
    Nokogiri::XML(File.read("#{icons_path(icon_type)}/#{icon_name}.svg"))
  end

  def icons_path(icon_type)
    Rails.public_path.join("assets/icons/#{icon_type}")
  end
end
