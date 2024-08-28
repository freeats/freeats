# frozen_string_literal: true

require "test_helper"

class ATS::QuickSearchControllerTest < ActionDispatch::IntegrationTest
  test "fetch candidates by admin account" do
    sign_in accounts(:admin_account)

    t1 = Time.zone.now
    t2 = t1.yesterday
    candidate1 = candidates(:jake)
    candidate2 =
      candidates(:john).tap { _1.update!(full_name: "Sláv Lem", last_activity_at: t1) }
    candidate3 =
      candidates(:sam).tap { _1.update!(full_name: "Sláv Vozniak", last_activity_at: t2) }

    get ats_quick_search_index_path,
        params: { q: candidate1.candidate_emails.first, searching_for: :candidate }

    assert_response :success
    assert_not_empty response.body, "Response body is empty"

    option = Nokogiri::HTML(response.body).at_css("option")

    assert_equal option.attr("value"), candidate1.id.to_s
    assert_equal option.attr("label"), candidate1.full_name
    assert_equal option.attr("optgroup"), "candidate"

    get ats_quick_search_index_path,
        params: { q: "slav", searching_for: :candidate }

    assert_response :success

    options = Nokogiri::HTML(response.body).css("option")

    [candidate2, candidate3].sort_by { |c| - c.last_activity_at.to_i }.each_with_index do |c, i|
      assert_equal options[i].attr("value"), c.id.to_s
      assert_equal options[i].attr("label"), c.full_name
      assert_equal options[i].attr("optgroup"), "candidate"
    end

    get ats_quick_search_index_path,
        params: { q: " Sláv Lem ", searching_for: :candidate }

    assert_response :success

    option = Nokogiri::HTML(response.body).at_css("option")

    assert_equal option.attr("value"), candidate2.id.to_s
    assert_equal option.attr("label"), candidate2.full_name
    assert_equal option.attr("optgroup"), "candidate"
  end

  test "fetch positions by admin account" do
    sign_in accounts(:admin_account)

    p1 = positions(:closed_position).tap { _1.update!(name: "TypeScript developer") }
    p2 = positions(:ruby_position).tap { _1.update!(name: "JavaScript developer") }

    get ats_quick_search_index_path,
        params: { q: "TypeScript", searching_for: :position }

    assert_response :success
    assert_not_empty response.body, "Response body is empty"

    option = Nokogiri::HTML(response.body).at_css("option")

    assert_equal option.attr("value"), p1.id.to_s
    assert_equal option.attr("label"), p1.name
    assert_equal option.attr("optgroup"), "position"

    get ats_quick_search_index_path,
        params: { q: "Script", searching_for: :position }

    assert_response :success

    options = Nokogiri::HTML(response.body).css("option").sort_by { |o| o.attr("value") }

    [p2, p1].each_with_index do |p, i|
      assert_equal options[i].attr("value"), p.id.to_s
      assert_equal options[i].attr("label"), p.name
      assert_equal options[i].attr("optgroup"), "position"
    end
  end

  test "should not allow to fetch candidates or positions by interviewer account" do
    sign_in accounts(:interviewer_account)

    get ats_quick_search_index_path,
        params: { q: " Sláv Lem ", searching_for: :candidate }

    assert_response :redirect

    get ats_quick_search_index_path,
        params: { q: "TypeScript", searching_for: :position }

    assert_response :redirect
  end

  test "fetch positions by hiring_manager account" do
    account = accounts(:hiring_manager_account)

    sign_in account

    golang_position = positions(:golang_position)
    ruby_position = positions(:ruby_position)

    assert_includes golang_position.hiring_manager_ids, account.member.id
    assert_not_includes ruby_position.hiring_manager_ids, account.member.id

    get ats_quick_search_index_path,
        params: { q: "gol", searching_for: :position }

    assert_response :success

    option = Nokogiri::HTML(response.body).at_css("option")

    assert_equal option.attr("value"), golang_position.id.to_s
    assert_equal option.attr("label"), golang_position.name

    get ats_quick_search_index_path,
        params: { q: "ruby", searching_for: :position }

    assert_response :success
    assert_empty response.body, "Response body is not empty"
  end

  test "fetch candidates by hiring_manager account" do
    account = accounts(:hiring_manager_account)

    sign_in account

    visible_candidate = candidates(:sam)
    visible_candidate_placement = placements(:sam_golang_sourced)
    not_visible_candidate = candidates(:john)
    not_visible_candidate_placement = placements(:john_ruby_replied)

    assert_equal visible_candidate_placement.candidate_id, visible_candidate.id
    assert_includes visible_candidate_placement.position.hiring_manager_ids, account.member.id
    assert_equal not_visible_candidate_placement.candidate_id, not_visible_candidate.id
    assert_not_includes not_visible_candidate_placement.position.hiring_manager_ids, account.member.id

    get ats_quick_search_index_path,
        params: { q: visible_candidate.full_name, searching_for: :candidate }

    assert_response :success

    option = Nokogiri::HTML(response.body).at_css("option")

    assert_equal option.attr("value"), visible_candidate.id.to_s
    assert_equal option.attr("label"), visible_candidate.full_name

    get ats_quick_search_index_path,
        params: { q: not_visible_candidate.full_name, searching_for: :candidate }

    assert_response :success
    assert_empty response.body, "Response body is not empty"
  end
end
