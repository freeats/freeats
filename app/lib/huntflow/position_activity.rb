# frozen_string_literal: true

class Huntflow::PositionActivity
  attr_reader :id, :state, :hold_reason, :close_reason, :created, :employment_date, :user

  def initialize(params)
    @id = params[:id]
    @state = params[:state]
    @hold_reason = params[:account_vacancy_hold_reason]
    @close_reason = params[:account_vacancy_close_reason]
    @created = Time.zone.parse(params[:created]) if params[:created]
    @employment_date = params[:employment_date]
    @user = Huntflow::User.new(params[:account_data]) if params[:account_data]
  end
end
