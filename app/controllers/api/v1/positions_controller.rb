# frozen_string_literal: true

class API::V1::PositionsController < AuthorizedController
  before_action :authorize!

  def fetch_positions
    positions =
      Position
      .where.not(status: :closed)
    dataset =
      positions
      .search_by_name(params[:q])
      .order(:status, :name)
      .limit(20)
    result = dataset.map do |position|
      {
        id: position.id,
        name: position.name,
        status: position.status
      }
    end
    render json: result, status: :accepted
  end
end
