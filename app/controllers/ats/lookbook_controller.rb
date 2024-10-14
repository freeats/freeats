# frozen_string_literal: true

class ATS::LookbookController < AuthorizedController
  before_action { authorize! :lookbook }

  def fetch_options_for_select_component_preview
    candidate = Struct.new(:id, :name, :candidate_emails)
    candidates = [
      candidate.new(1, "John Doe", ["john@doe.com"]),
      candidate.new(2, "Jane Doe", ["jane@doe.com"]),
      candidate.new(3, "John Smith", ["john@smith.com"]),
      candidate.new(4, "Jane Smith", ["jane@smith.com"]),
      candidate.new(5, "John Johnson", ["john@johnson.com"]),
      candidate.new(6, "Jane Johnson", ["jane@johnson.com"])
    ]

    respond_to do |format|
      format.html do
        options = candidates.map { { candidate: _1, disabled: ["", "disabled"].sample } }
        render partial: "candidate_options", locals: { options: }
      end
      format.json do
        options =
          candidates.map { { value: _1.id, text: _1.name, disabled: ["", "disabled"].sample } }
        render json: options
      end
    end
  end
end
