# frozen_string_literal: true

class Note < ApplicationRecord
  has_and_belongs_to_many :reacted_members,
                          class_name: "Member",
                          join_table: :note_reactions

  belongs_to :note_thread
  belongs_to :member

  def self.mentioned_members_ids(text)
    return [] if text.blank?

    Member.mentioned_in(text).ids
  end

  def self.mark_mentions(text)
    Member
      .joins(:account)
      .mentioned_in(text)
      .pluck("accounts.name")
      .reduce(text) do |result, account_name|
      result.gsub("@#{account_name}", "<span class='text-primary'>#{account_name}</span>")
    end
  end

  def reacted_member_names(current_member)
    return unless current_member

    reacted_names =
      reacted_members.includes(:account).map { _1.account.name }.sort

    if reacted_members.include?(current_member)
      reacted_names.delete(current_member.account.name)
      reacted_names.unshift("You")
    end
    reacted_names
  end

  def url(reply: false)
    case note_thread.notable_type
    when "Candidate"
      Rails.application.routes.url_helpers.tab_ats_candidate_url(
        note_thread.notable_id,
        tab: "info",
        reply: reply || nil,
        anchor: "note-#{id}",
        host: ENV.fetch("HOST_URL", "localhost:3000"),
        protocol: ATS::Application.config.force_ssl ? "https" : "http"
      )
    else
      raise "Unsupported model"
    end
  end
end
