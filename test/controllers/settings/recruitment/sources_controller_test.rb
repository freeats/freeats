# frozen_string_literal: true

require "test_helper"

class Settings::Recruitment::SourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_account = accounts(:admin_account)
    sign_in @current_account
  end

  test "should open sources recruitment settings" do
    get settings_recruitment_sources_path

    assert_response :success
  end

  test "should add source" do
    old_sources = CandidateSource.where(tenant: tenants(:toughbyte_tenant)).to_a
    new_source_name = "Abracadabra"
    current_sources_params =
      old_sources.map.with_index do |source, idx|
        [(idx + 1).to_s, { "id" => source.id, "name" => source.name }]
      end
    params = {
      "tenant" => {
        "candidate_sources_attributes" => (
          current_sources_params + [[(old_sources.size + 1).to_s,
                                     { "name" => new_source_name }]]
        ).to_h
      }
    }

    assert_difference "CandidateSource.count", 1 do
      post update_all_settings_recruitment_sources_path(params)
    end

    assert_response :success

    new_sources = CandidateSource.where(tenant: tenants(:toughbyte_tenant)).to_a

    assert_includes new_sources, CandidateSource.find_by(name: new_source_name)
    old_sources.each do |source|
      assert_includes new_sources, source
    end
  end

  test "should show modal if remove source" do
    old_sources = CandidateSource.all.to_a
    new_sources = old_sources.filter { _1.name == "LinkedIn" }
    current_sources_params =
      new_sources.map.with_index do |source, idx|
        [(idx + 1).to_s, { "id" => source.id, "name" => source.name }]
      end
    params = {
      "tenant" => {
        "candidate_sources_attributes" => current_sources_params.to_h
      }
    }

    assert_no_difference "CandidateSource.count" do
      post update_all_settings_recruitment_sources_path(params)
    end

    assert_response :success
    assert_includes response.body,
                    "Source HeadHunter will be permanently removed from any candidates that have it set."
  end

  test "should remove source if modal shown" do
    new_sources = [candidate_sources(:linkedin)]
    removed_source = candidate_sources(:headhunter)
    candidates_with_removed_source = removed_source.candidates

    current_sources_params =
      new_sources.map.with_index do |source, idx|
        [(idx + 1).to_s, { "id" => source.id, "name" => source.name }]
      end
    params = {
      modal_shown: "true",
      "tenant" => {
        "candidate_sources_attributes" => current_sources_params.to_h
      }
    }

    assert_difference "CandidateSource.count", -1 do
      post update_all_settings_recruitment_sources_path(params)
    end

    assert_response :success

    assert candidates_with_removed_source.all? { _1.reload.candidate_source_id.nil? }
  end
end
