# frozen_string_literal: true

module ATS::MembersHelper
  def compose_member_options_for_select(excluded_member_ids:, unassignment_label:)
    dataset = Member.active.where.not(id: excluded_member_ids).order("accounts.name").to_a

    if dataset.include?(current_member)
      dataset -= [current_member]
      dataset.unshift(current_member)
    end

    partials = dataset.map do |member|
      controller.render_to_string(partial: "ats/members/member_element", locals: { member: })
    end

    if unassignment_label.present?
      nil_partial = content_tag(:div, class: "d-flex align-items-center") do
        concat(
          content_tag(
            :span,
            class: "d-inline-flex align-items-center justify-content-center me-2",
            style: "min-width: 32px; min-height: 32px;"
          ) do
            render(IconComponent.new(:ban, size: :medium))
          end
        )
        concat(unassignment_label)
      end
      nil_member = Struct.new(:id, :name).new("", "")

      partials.unshift(nil_partial)
      dataset.unshift(nil_member)
    end

    dataset.zip(partials).map do |data, partial|
      tag.option(value: data.id, label: data.name) { partial }
    end.join
  end

  def invite_member_button
    render ButtonLinkComponent.new(
      invite_modal_ats_members_path,
      size: :small,
      data: { turbo_frame: :turbo_modal_window }
    ).with_content(t("user_accounts.invite"))
  end

  def deactivate_member_button(account)
    tooltip_text =
      if account.id == current_account.id
        t("user_accounts.deactivate_self_error")
      else
        ""
      end

    form_with(
      url: deactivate_ats_member_path(account.id),
      method: :patch,
      class: "vstack"
    ) do
      render ButtonComponent.new(
        variant: :danger_secondary,
        disabled: tooltip_text.present?,
        size: :tiny,
        tooltip_title: tooltip_text,
        class: "w-100",
        data: {
          toggle: "ats-confirmation",
          title: t("user_accounts.deactivate_title", name: account.name),
          btn_cancel_label: t("core.cancel_button"),
          btn_ok_label: t("user_accounts.deactivate"),
          btn_ok_class: "btn btn-danger btn-small"
        }
      ).with_content(t("user_accounts.deactivate"))
    end
  end

  def reinvite_member_button(model)
    form_with(url: invite_ats_members_path(email: model.email), class: "vstack") do
      render ButtonComponent.new(
        variant: :secondary,
        size: :tiny
      ).with_content(t("user_accounts.reinvite"))
    end
  end

  def reactive_button(account)
    form_with(
      url: reactivate_ats_member_path(account.id),
      method: :patch,
      class: "vstack"
    ) do
      render ButtonComponent.new(
        variant: :secondary,
        size: :tiny
      ).with_content(t("user_accounts.reactivate"))
    end
  end

  def change_access_level_button(account, current_member)
    return account.access_level.humanize if account.access_level == "invited"
    return account.access_level.humanize unless current_member.admin?
    return account.access_level.humanize if account.id == current_member.account.id

    return account.access_level.humanize if account.access_level == "inactive"

    access_levels_options =
      %w[admin member]
      .map do |access_level|
        { text: access_level.humanize, value: access_level,
          selected: access_level == account.access_level }
      end

    form_with(
      url: update_level_access_ats_member_path(account.id),
      class: "turbo-instant-submit",
      method: :patch
    ) do |form|
      render SingleSelectComponent.new(
        form,
        method: :access_level,
        size: :tiny,
        required: true,
        anchor_dropdown_to_body: true,
        local: { options: access_levels_options }
      )
    end
  end
end
