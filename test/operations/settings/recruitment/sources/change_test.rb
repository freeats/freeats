# frozen_string_literal: true

require "test_helper"

class Settings::Recruitment::Sources::ChangeTest < ActionDispatch::IntegrationTest
  include Dry::Monads[:result]

  test "should return linkedin_source_cannot_be_changed" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    other_source = candidate_sources(:headhunter)
    linkedin_source = candidate_sources(:linkedin)

    assert_equal ActsAsTenant.current_tenant.candidate_sources.sort,
                 [linkedin_source, other_source].sort
    new_candidate_sources =
      [other_source]

    candidate_sources_params =
      new_candidate_sources.map do |source|
        { name: source.name, id: source.id.to_s }
      end
    result = Settings::Recruitment::Sources::Change.new(
      candidate_sources_params:,
      actor_account: nil
    ).call.failure

    assert_equal result[0], :linkedin_source_cannot_be_changed
  end

  test "should return candidate_source_not_found if source is not found" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    source_for_removing = candidate_sources(:headhunter)
    linkedin_source = candidate_sources(:linkedin)
    current_tenant_candidate_sources =
      [linkedin_source, source_for_removing]

    candidate_sources_params =
      current_tenant_candidate_sources.map do |source|
        { name: source.name, id: source.id.to_s }
      end
    source_for_removing.destroy!

    result = Settings::Recruitment::Sources::Change.new(
      candidate_sources_params:,
      actor_account: nil
    ).call.failure

    assert_equal result[0], :candidate_source_not_found
  end
end
