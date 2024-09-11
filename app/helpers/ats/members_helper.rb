# frozen_string_literal: true

module ATS::MembersHelper
  def compose_member_options_for_select(unassignment_label:)
    dataset = Member.active.order("accounts.name")

    if dataset.include?(current_member)
      dataset -= [current_member]
      dataset.unshift(current_member)
    end

    partials = dataset.map do |member|
      controller.render_to_string(partial: "ats/members/member_element", locals: { member: })
    end

    if unassignment_label.present?
      nil_partial = ActionController::Base.helpers.sanitize(
        "<div><i class='fas fa-ban pe-2 ms-1'></i>#{unassignment_label}</div>"
      )
      nil_member = Struct.new(:id, :name).new("", "")

      partials.unshift(nil_partial)
      dataset.unshift(nil_member)
    end

    dataset.zip(partials).map do |data, partial|
      tag.option(value: data.id, label: data.name) { partial }
    end.join
  end
end
