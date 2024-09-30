# frozen_string_literal: true

class PrettyNumberComponentPreview < ViewComponent::Preview
  # @!group Variants
  def simple_number
    render PrettyNumberComponent.new(123_456_789, html: false)
  end

  # @param to
  def range(to: 987_654.321)
    render PrettyNumberComponent.new(123_456_789, to:, html: false)
  end

  # @param object
  def with_object(object: "cat")
    render PrettyNumberComponent.new(123_456_789, object:, html: false)
  end

  # @param suffix
  def with_suffix(suffix: "RUB")
    render PrettyNumberComponent.new(123_456_789, suffix:, html: false)
  end

  # @param immediate_suffix
  def with_immediate_suffix(immediate_suffix: "+")
    render PrettyNumberComponent.new(123_456_789, immediate_suffix:, html: false)
  end

  # @param object
  def html_single_object(object: "member")
    render PrettyNumberComponent.new("1", object:)
  end

  # @param to
  # @param immediate_suffix
  def html_to_with_immediate_suffix(to: 987_654.321, immediate_suffix: "+")
    render PrettyNumberComponent.new(123_456_789, to:, immediate_suffix:)
  end

  # @param to
  # @param object
  # @param suffix
  # @param immediate_suffix
  def html_all_params(to: 987_654.321, object: "cat", suffix: "RUB", immediate_suffix: "+")
    render PrettyNumberComponent.new(123_456_789, to:, object:, suffix:, immediate_suffix:)
  end
  # @!endgroup
end
