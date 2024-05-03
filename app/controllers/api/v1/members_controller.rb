# frozen_string_literal: true

class API::V1::MembersController < ApplicationController
  before_action :authorize!

  def fetch_members
    access_level = params[:access_level]
    allow_nil = params[:allow_nil] == "true"
    dataset = Member.active
    dataset = dataset.where(access_level:) if access_level.present?
    dataset = [current_member] + dataset.reject { _1 == current_member }
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
