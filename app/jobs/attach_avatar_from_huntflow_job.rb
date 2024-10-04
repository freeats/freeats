# frozen_string_literal: true

class AttachAvatarFromHuntflowJob < ApplicationJob
  def perform(candidate_id:, avatar_url:)
    candidate = Candidate.find_by(id: candidate_id)

    return unless candidate

    avatar_io = URI.parse(avatar_url).open

    extention_name = MiniMime.lookup_by_content_type(avatar_io.content_type).extension
    candidate.avatar.attach(io: avatar_io, filename: "avatar.#{extention_name}")
  end
end
