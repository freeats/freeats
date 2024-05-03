# frozen_string_literal: true

require "test_helper"

class SequenceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @actor_account = accounts(:employee_account)
    @sequence_template = sequence_templates(:ruby_position_sequence_template)
    @member_email_address = member_email_addresses(:admin_first_email_address)
    @placement = placements(:sam_ruby_replied)
  end

  test "should create sequence" do
    existing_sequence = sequences(:ruby_position_sam)
    existing_sequence.update!(status: :stopped)

    params = {
      sequence_template: @sequence_template,
      member_email_address: @member_email_address,
      placement: @placement,
      to: "sam@smith.com"
    }
    now = Time.zone.now

    Time.zone.stub(:now, now) do
      assert_difference "Sequence.count" do
        sequence = Sequences::Add.new(params:, actor_account: @actor_account).call.value!

        assert_equal sequence.status, "running"
        assert_equal sequence.current_stage, 0
        assert_equal sequence.member_email_address_id, @member_email_address.id
        assert_equal sequence.placement_id, @placement.id
        assert_equal sequence.sequence_template_id, @sequence_template.id
        assert_equal sequence.to, params[:to]
        assert_equal sequence.scheduled_at, now
        assert_equal sequence.data,
                     [{ "body" => "Hi there! We are excited to have you apply for the Ruby position",
                        "subject" => "Ruby position",
                        "position" => 1,
                        "delay_in_days" => nil }]
      end
    end
  end

  test "should not create sequence if `to` field contains " \
       "an email that belongs to the blacklisted candidate" do
    blacklisted_candidate = candidates(:john_duplicate)

    params = {
      sequence_template: @sequence_template,
      member_email_address: @member_email_address,
      placement: @placement,
      to: blacklisted_candidate.all_emails(status: :current).first
    }

    assert_no_difference "Sequence.count" do
      case Sequences::Add.new(params:, actor_account: @actor_account).call
      in Failure[:blacklisted_candidate, error]
        assert_equal error,
                     "Sequence can't be sent for <a href=#{blacklisted_candidate.url}>" \
                     "#{blacklisted_candidate.full_name}</a> marked as Blacklisted."
      end
    end
  end

  test "should not create sequence if sequence template variables are missing" do
    existing_sequence = sequences(:ruby_position_sam)
    existing_sequence.update!(status: :stopped)

    params = {
      sequence_template: @sequence_template,
      member_email_address: @member_email_address,
      placement: @placement,
      to: "sam@smith.com"
    }
    missing_variable = "{{missing_variable}}"
    rich_text = action_text_rich_texts(:ruby_position_first_stage_body)
    rich_text.update!(body: "Hello, #{missing_variable}")

    assert_no_difference "Sequence.count" do
      case Sequences::Add.new(params:, actor_account: @actor_account).call
      in Failure[:missing_variables, error]
        assert_equal error, "Missing required sequence template variables: #{missing_variable}."
      end
    end
  end

  test "should not create a sequence if there is already a running sequence for one of the recipient emails" do
    running_sequence = sequences(:ruby_position_sam)

    assert_equal running_sequence.status, "running"

    params = {
      sequence_template: @sequence_template,
      member_email_address: @member_email_address,
      placement: @placement,
      to: running_sequence.to
    }

    assert_no_difference "Sequence.count" do
      case Sequences::Add.new(params:, actor_account: @actor_account).call
      in Failure[:running_sequence, error]
        assert_equal error, "There's already a running sequence for #{running_sequence.to}."
      end
    end
  end

  test "should not create a sequence if the token is blank for the member email address" do
    member_email_address = member_email_addresses(:admin_second_email_address)

    assert_predicate member_email_address.token, :blank?

    params = {
      sequence_template: @sequence_template,
      member_email_address:,
      placement: @placement,
      to: "sam@smith.com"
    }

    assert_no_difference "Sequence.count" do
      case Sequences::Add.new(params:, actor_account: @actor_account).call
      in Failure[:token_is_blank, error]
        assert_equal error, "Token is blank for #{member_email_address.address}."
      end
    end
  end
end
