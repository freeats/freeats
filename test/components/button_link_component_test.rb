# frozen_string_literal: true

require "test_helper"

class ButtonLinkComponentTest < ViewComponent::TestCase
  test "default button link component" do
    assert_equal(
      render_inline(ButtonLinkComponent.new("#").with_content("ButtonLink")).to_html,
      %(<a class="btn d-inline-flex gap-2 align-items-center justify-content-center
        text-nowrap btn-primary btn-medium" href="#">ButtonLink</a>).squish
    )
  end
end
