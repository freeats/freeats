# frozen_string_literal: true

class API::V1::MembersController < ApplicationController
  def fetch_members
    allow_nil = params[:allow_nil] == "true"
    dataset = Member.active.where.not(id: current_member.id)
    data =
      if allow_nil
        [
          {
            value: "",
            text: "",
            html: ActionController::Base.helpers.sanitize(
              "<div><i class='fas fa-ban pe-2'></i>#{params[:unassignment_option]}</div>"
            )
          }
        ]
      else
        []
      end
    data << dataset.map do |member|
      {
        value: member.id,
        text: member.account.name,
        html: render_to_string(
          "ats/members/member_element",
          formats: %i[html],
          layout: nil,
          locals: { member: }
        )
      }
    end
    render json: data
  end
end
