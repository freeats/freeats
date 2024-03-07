# frozen_string_literal: true

class PrettyNumberComponent < ApplicationComponent
  include ActionView::Helpers::NumberHelper

  param :number, Types::Strict::Integer | Types::Strict::Float | Types::Strict::String.optional
  option :to, Types::Strict::Integer | Types::Strict::Float | Types::Strict::String.optional,
         optional: true
  option :object, Types::Strict::String.optional, optional: true
  option :suffix, Types::Strict::String.optional, optional: true
  option :immediate_suffix, Types::Strict::String.optional, optional: true
  option :html, Types::Strict::Bool, default: -> { true }

  def call
    return if number.nil?

    num = to_num(number)
    numbers_are_integer = to.nil? ? num.integer? : (num.integer? && to_num(to).integer?)

    result = prettify_number(number, numbers_are_integer:).to_s
    result = to_html(result) if html
    result += immediate_suffix.to_s if immediate_suffix.present? && to.blank?

    if to.present?
      res_to = prettify_number(to, numbers_are_integer:).to_s
      res_to = to_html(res_to) if html
      result += " - "
      result += res_to
    end

    if object.present?
      result +=
        if num == 1 && to.blank? && immediate_suffix.blank?
          " #{object.singularize}"
        else
          " #{object.pluralize}"
        end
    end
    result += " #{suffix}" if suffix.present?

    result
  end

  private

  def prettify_number(number, numbers_are_integer:)
    if numbers_are_integer
      number_with_delimiter(number, delimiter: "\u00A0")
    else
      number_with_delimiter(number.to_f, delimiter: "\u00A0", separator: ".")
    end
  end

  def to_num(number)
    if number.is_a?(String)
      number.include?(".") ? number.to_f : number.to_i
    else
      number
    end
  end

  def to_html(string)
    substrings = string.split("\u00A0")
    safe_join(
      [
        *substrings[0...-1].map do |substring|
          tag.span(class: "pretty-number-component") { substring }
        end,
        substrings.last
      ]
    )
  end
end
