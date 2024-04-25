# frozen_string_literal: true

require "test_helper"

class SequenceTemplateTest < ActiveSupport::TestCase
  test "should compose new sequence_template" do
    position = positions(:ruby_position)

    sequence_template_new = SequenceTemplates::New.new(position_id: position.id).call.value!

    assert_equal sequence_template_new.position_id, position.id
    assert_equal sequence_template_new.name, position.name
    assert_equal sequence_template_new.subject, position.name

    stages = sequence_template_new.stages

    assert_equal stages.map { { position: _1.position, delay_in_days: _1.delay_in_days } },
                 SequenceTemplate::DEFAULT_STAGES
  end
end
