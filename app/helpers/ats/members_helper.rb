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

  def invate_member_button
    render ButtonLinkComponent.new(
      invite_modal_ats_members_path,
      size: :medium,
      data: { turbo_frame: :turbo_modal_window }
    ).with_content(I18n.t("user_accounts.invite"))
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
      method: :patch
    ) do
      render ButtonComponent.new(
        variant: :danger_secondary,
        disabled: tooltip_text.present?,
        tooltip_title: tooltip_text,
        data: {
          toggle: "ats-confirmation",
          title: t("user_accounts.deactivate_title", name: account.name),
          btn_cancel_label: t("core.cancel_button"),
          btn_ok_label: t("user_accounts.deactivate"),
          btn_ok_class: "btn btn-danger btn-small"
        }
      ).with_content(I18n.t("user_accounts.deactivate"))
    end
  end

  def reinvite_member_button(model)
    form_with(url: invite_ats_members_path(email: model.email)) do
      render ButtonComponent.new(
        variant: :secondary
      ).with_content(I18n.t("user_accounts.reinvite"))
    end
  end

  def reactive_button(account)
    form_with(
      url: reactivate_ats_member_path(account.id),
      method: :patch
    ) do
      render ButtonComponent.new(
        variant: :secondary
      ).with_content(I18n.t("user_accounts.reactivate"))
    end
  end

  def change_access_level_button(account, current_member)
    return account.access_level if account.access_level == "invited"
    return account.access_level unless current_member.admin?
    return account.access_level if account.id == current_member.account.id

    return account.access_level if account.access_level == "inactive"

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
        required: true,
        local: { options: access_levels_options }
      )
    end
  end
end
