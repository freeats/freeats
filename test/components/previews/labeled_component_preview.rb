# frozen_string_literal: true

class LabeledComponentPreview < ViewComponent::Preview
  # @!group Variants
  # @param size select { choices: [small, medium] }
  def show_card_row(size: :medium)
    view_content_size = { small: "-sm", medium: "" }[size]
    render(LabeledComponent.new(right_class: "col-form-label#{view_content_size}")) do |c|
      c.with_label("Label", size:)
      "Value"
    end
  end

  def edit_card_row(size: :medium)
    render(LabeledComponent.new) do |c|
      c.with_label("Label", size:, for_field: :candidate_name, class: "fw-semibold")
      # Rendering component inside component:
      # https://github.com/ViewComponent/view_component/issues/201
      TextInputComponent
        .new("candidate[name]", size:)
        .render_in(ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil))
    end
  end

  def without_label(size: :medium)
    render(LabeledComponent.new) do
      ButtonComponent
        .new(size:)
        .with_content("Delete")
        .render_in(ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil))
    end
  end

  def non_standard(size: :medium)
    render(LabeledComponent.new(left_layout_class: "col-3", class: "align-items-center")) do |c|
      c.with_label("Label", size:, for_field: :candidate_company, class: "fw-semibold")
      TextInputComponent
        .new("candidate[company]", size:)
        .render_in(ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil))
    end
  end
  # @!endgroup
end
