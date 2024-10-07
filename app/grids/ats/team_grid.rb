# frozen_string_literal: true

class ATS::TeamGrid
  include Datagrid

  scope do
    accounts_query =
      Account
      .joins(:member)
      .select("name, email, access_level, created_at, accounts.id")

    access_tokens_query =
      AccessToken
      .where(sent_at: AccessToken::MEMBER_INVITATION_TTL.ago..)
      .select(:sent_to, :id)

    combined_results =
      accounts_query.to_a + access_tokens_query.map do |token|
        InvitedMember.new(
          name: nil,
          email: token.sent_to,
          access_level: "invited",
          created_at: nil,
          id: token.id
        )
      end

    combined_results.sort_by { |model| [model.name.nil? ? 0 : 1, model.name] }
  end

  attr_accessor(:current_member)

  column(:avatar, html: true, header: "", order: false) do |model|
    picture_avatar_icon model.avatar, {}, class: "small-avatar-thumbnail"
  end

  column(:name, header: I18n.t("core.name"), order: false)

  column(:email, header: I18n.t("core.email"), order: false, &:email)

  column(:account_status, header: I18n.t("user_accounts.status"), html: true,
                          order: false) do |model, grid|
    change_access_level_button(model, grid.current_member)
  end

  column(:joined_on, header: I18n.t("user_accounts.joined_on"), order: false) do |model|
    model&.created_at&.to_fs(:date)
  end

  column(
    :action,
    header: "",
    order: false,
    html: true,
    class: "grid-column-35",
    if: proc { |grid| grid.current_member.admin? }
  ) do |model|
    if model.access_level == "invited"
      reinvite_member_button(model)
    elsif model.access_level == "inactive"
      reactive_button(model)
    else
      deactivate_member_button(model)
    end
  end
end
