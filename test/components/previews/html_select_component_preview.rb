# frozen_string_literal: true

class HtmlSelectComponentPreview < ViewComponent::Preview
  # @!group Variants
  # @param size select { choices: [tiny, small, medium] }
  # @param placeholder text
  def local(size: :medium, placeholder: local_placeholder)
    render(
      HtmlSelectComponent.new(
        "name",
        local: { options: ApplicationController.helpers.options_for_priority(priorities) },
        size:,
        item_as_rich_text: true,
        placeholder:
      )
    )
  end

  def local_filled(size: :medium, placeholder: local_placeholder)
    render(
      HtmlSelectComponent.new(
        "name",
        local: { options: ApplicationController.helpers.options_for_priority(priorities, "medium") },
        size:,
        item_as_rich_text: true,
        placeholder:
      )
    )
  end

  def disabled(size: :medium, placeholder: local_placeholder)
    render(
      HtmlSelectComponent.new(
        "name",
        local: { options: ApplicationController.helpers.options_for_priority(priorities, "medium") },
        size:,
        disabled: true,
        item_as_rich_text: true,
        placeholder:
      )
    )
  end

  def readonly(size: :medium, placeholder: local_placeholder)
    render(
      HtmlSelectComponent.new(
        "name",
        local: { options: ApplicationController.helpers.options_for_priority(priorities, "medium") },
        size:,
        readonly: true,
        item_as_rich_text: true,
        placeholder:
      )
    )
  end

  def remote(size: :medium, placeholder: remote_placeholder)
    render(
      HtmlSelectComponent.new(
        "name",
        remote: { search_url: },
        size:,
        placeholder:
      )
    )
  end

  def remote_filled(size: :medium, placeholder: remote_placeholder)
    render(
      HtmlSelectComponent.new(
        "name",
        remote: {
          search_url:,
          options: candidate_options(with_selected: true)
        },
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
         .fetch_options_for_select_component_preview_ats_lookbook_path(q: "QUERY", format: :html)
  end

  def candidate_options(with_selected: false)
    candidate_struct = Struct.new(:id, :name, :candidate_emails)
    candidates = [
      candidate_struct.new(1, "John Doe", ["john@doe.com"]),
      candidate_struct.new(2, "Jane Doe", ["jane@doe.com"]),
      candidate_struct.new(3, "John Smith", ["john@smith.com"])
    ]
    options = candidates.map do |candidate|
      { candidate: }
    end
    options[1][:selected] = "selected" if with_selected
    options[2][:disabled] = "disabled"

    ApplicationController.new.render_to_string(
      partial: "ats/lookbook/candidate_options", locals: { options: }
    )
  end

  def local_placeholder
    "Select priority"
  end

  def remote_placeholder
    "Type the candidate's name to search"
  end

  def priorities
    {
      low: "low",
      medium: "medium",
      high: "high"
    }
  end
end
