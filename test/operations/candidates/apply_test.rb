# frozen_string_literal: true

require "test_helper"

class Candidates::ApplyTest < ActionDispatch::IntegrationTest
  include Dry::Monads[:result]

  test "apply should create candidate, placement and task and assign recruiter" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    position = positions(:ruby_position)
    tempfile = fixture_file_upload("empty.pdf", "application/pdf")
    file =
      ActionDispatch::Http::UploadedFile.new(
        {
          filename: "empty.pdf",
          type: "application/pdf",
          tempfile:
        }
      )

    candidate_params = { full_name: "John Smith", email: "KdQ5j@example.com", file: }

    assert_difference "Event.where(type: 'active_storage_attachment_added').count", 1 do
      assert_difference "Event.where(type: 'candidate_changed', changed_field: 'cv').count", 1 do
        assert_difference "Candidate.count", 1 do
          assert_difference "Placement.count", 1 do
            assert_difference "Task.count", 1 do
              Candidates::Apply.new(
                params: candidate_params,
                position_id: position.id,
                actor_account: nil
              ).call.value!
            end
          end
        end
      end
    end

    candidate = Candidate.last
    placement = candidate.placements.first
    task = candidate.tasks.first

    assert_equal candidate.full_name, candidate_params[:full_name]
    assert_equal candidate.emails, [candidate_params[:email].downcase]
    assert_equal candidate.recruiter_id, position.recruiter_id
    assert_predicate candidate.cv, :present?

    assert_equal placement.stage, "Replied"
    assert_equal placement.position_id, position.id
    assert_equal placement.candidate_id, candidate.id
    assert_equal placement.status, "qualified"

    assert_equal task.taskable, candidate
    assert_equal task.assignee_id, position.recruiter_id
    assert_equal task.status, "open"
    assert_equal task.name, "Reply to application to Ruby developer"
    assert_equal task.description, ""
  end

  test "apply should not create candidate, placement and task and assign recruiter " \
       "if email address is invalid" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    position = positions(:ruby_position)
    tempfile = fixture_file_upload("empty.pdf", "application/pdf")
    file =
      ActionDispatch::Http::UploadedFile.new(
        {
          filename: "empty.pdf",
          type: "application/pdf",
          tempfile:
        }
      )

    candidate_params = { full_name: "John Smith", email: "invalidaddress.com", file: }

    assert_no_difference "Event.where(type: 'active_storage_attachment_added').count" do
      assert_no_difference "Event.where(type: 'candidate_changed', changed_field: 'cv').count" do
        assert_no_difference "Candidate.count" do
          assert_no_difference "Placement.count" do
            assert_no_difference "Task.count" do
              result = Candidates::Apply.new(
                params: candidate_params,
                position_id: position.id,
                actor_account: nil
              ).call.failure

              assert_equal result[0], :candidate_invalid
              assert_equal result[1].errors.full_messages,
                           [
                             "Address have invalid value: invalidaddress.com",
                             "Candidate email addresses address have invalid value: invalidaddress.com"
                           ]
            end
          end
        end
      end
    end
  end

  test "apply should not create candidate, placement and task and assign recruiter " \
       "if position recruter is blank or inactive" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    position = positions(:golang_position)
    tempfile = fixture_file_upload("empty.pdf", "application/pdf")
    file =
      ActionDispatch::Http::UploadedFile.new(
        {
          filename: "empty.pdf",
          type: "application/pdf",
          tempfile:
        }
      )

    candidate_params = { full_name: "John Smith", email: "KdQ5j@example.com", file: }

    assert_no_difference "Event.where(type: 'active_storage_attachment_added').count" do
      assert_no_difference "Event.where(type: 'candidate_changed', changed_field: 'cv').count" do
        assert_no_difference "Candidate.count" do
          assert_no_difference "Placement.count" do
            assert_no_difference "Task.count" do
              result = Candidates::Apply.new(
                params: candidate_params,
                position_id: position.id,
                actor_account: nil
              ).call.failure

              assert_equal result, :no_active_recruiter
            end
          end
        end
      end
    end

    position.update!(recruiter: members(:inactive_member))

    assert_no_difference "Event.where(type: 'active_storage_attachment_added').count" do
      assert_no_difference "Event.where(type: 'candidate_changed', changed_field: 'cv').count" do
        assert_no_difference "Candidate.count" do
          assert_no_difference "Placement.count" do
            assert_no_difference "Task.count" do
              result = Candidates::Apply.new(
                params: candidate_params,
                position_id: position.id,
                actor_account: nil
              ).call.failure

              assert_equal result, :no_active_recruiter
            end
          end
        end
      end
    end
  end
end