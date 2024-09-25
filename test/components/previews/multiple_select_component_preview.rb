# frozen_string_literal: true

class MultipleSelectComponentPreview < ViewComponent::Preview
  # @!group Variants
  # @param size select { choices: [tiny, small, medium] }
  # @param options text description "Use ', ' to separate options"
  # @param disabled_options text description "Use ', ' to separate options"
  # @param selected_options text description "Use ', ' to separate options"
  # @param placeholder text
  def local(
    size: :medium,
    options: default_options,
    disabled_options: default_disabled_options,
    selected_options: "",
    placeholder: local_placeholder
  )
    render(
      MultipleSelectComponent.new(
        "name",
        local: { options: setup_options(options:, disabled_options:, selected_options:) },
        size:,
        placeholder:
      )
    )
  end

  def local_filled(
    size: :medium,
    options: default_options,
    disabled_options: default_disabled_options,
    selected_options: default_selected_options,
    placeholder: local_placeholder
  )
    render(
      MultipleSelectComponent.new(
        "name",
        local: { options: setup_options(options:, disabled_options:, selected_options:) },
        size:,
        placeholder:
      )
    )
  end

  def disabled(
    size: :medium,
    options: default_options,
    disabled_options: default_disabled_options,
    selected_options: default_selected_options,
    placeholder: local_placeholder
  )
    render(
      MultipleSelectComponent.new(
        "name",
        local: { options: setup_options(options:, disabled_options:, selected_options:) },
        disabled: true,
        size:,
        placeholder:
      )
    )
  end

  def readonly(
    size: :medium,
    options: default_options,
    disabled_options: default_disabled_options,
    selected_options: default_selected_options,
    placeholder: local_placeholder
  )
    render(
      MultipleSelectComponent.new(
        "name",
        local: { options: setup_options(options:, disabled_options:, selected_options:) },
        readonly: true,
        size:,
        placeholder:
      )
    )
  end

  def remote(size: :medium, placeholder: remote_placeholder)
    render(
      MultipleSelectComponent.new(
        "name",
        remote: { search_url: },
        size:,
        placeholder:
      )
    )
  end

  def remote_filled(size: :medium, placeholder: remote_placeholder)
    candidate_struct = Struct.new(:id, :name)
    candidates = [
      candidate_struct.new(1, "John Doe"),
      candidate_struct.new(2, "Jane Doe")
    ]
    options = candidates.map do |candidate|
      { text: candidate.name, value: candidate.id }
    end
    options.first[:selected] = true
    options.last[:disabled] = true

    render(
      MultipleSelectComponent.new(
        "name",
        remote: { search_url:, options: },
        size:,
        placeholder:
      )
    )
  end
  # @!endgroup

  private

  def search_url
    Rails.application
         .routes
         .url_helpers
         .fetch_options_for_select_component_preview_ats_lookbook_path(q: "QUERY", format: :json)
  end

  def setup_options(options:, disabled_options: "", selected_options: "")
    (options.presence || default_options).split(", ").map do |option|
      selected = true if selected_options.split(", ").include?(option)
      disabled = true if disabled_options.split(", ").include?(option)
      {
        text: option.humanize,
        value: option,
        selected:,
        disabled:
      }.compact
    end
  end

  def default_options
    "one, two, three, four, five, six, one million twelve thousand four hundred and fifty-six"
  end

  def default_disabled_options
    "two, four"
  end

  def default_selected_options
    "three"
  end

  def local_placeholder
    "Select an option"
  end

  def remote_placeholder
    "Type candidate's name to search"
  end
end
