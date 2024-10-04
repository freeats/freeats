# frozen_string_literal: true

class Huntflow::Placement
  attr_reader :id, :position_id, :stage

  def initialize(params)
    @id = params[:id]
    @position_id = params[:vacancy]
    @stage = params[:status]
  end
end
