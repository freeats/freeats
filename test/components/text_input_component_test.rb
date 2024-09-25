# frozen_string_literal: true

require "test_helper"

class TextInputComponentTest < ViewComponent::TestCase
  test "text field tag" do
    assert_equal(
      render_inline(TextInputComponent.new("name")).to_html,
      "<input type=\"text\" name=\"name\" id=\"name\" " \
      "class=\"form-control text-input-component-default text-input-component-small\">"
    )
  end

  test "text field tag with subscript" do
    assert_equal(
      render_inline(TextInputComponent.new("name")) do |c|
        c.with_subscript("test", id: "someid")
      end.to_html.squish.gsub("> <", "><"),
      <<~HTML.squish.gsub("> <", "><")
        <div>
          <input type="text" name="name" id="name"
                 class="form-control text-input-component-default text-input-component-small"
                 aria-describedby="someid">
          <span id="someid" class="text-input-component-subscript">test</span>
        </div>
      HTML
    )
  end

  test "text input" do
    candidate = Struct.new(:id, :name).new(1, "John Doe")

    assert_equal(
      render_inline(TextInputComponent.new(form("candidate", candidate), method: :name)).to_html,
      "<input class=\"form-control text-input-component-default text-input-component-small\" " \
      "type=\"text\" value=\"#{candidate.name}\" name=\"candidate[name]\" id=\"candidate_name\">"
    )
  end

  private

  def form(object_name, object, template = ActionView::Base.empty, options = {})
    ActionView::Helpers::FormBuilder.new(object_name, object, template, options)
  end
end
