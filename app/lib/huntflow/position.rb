# frozen_string_literal: true

class Huntflow::Position
  attr_reader :id, :name, :created, :status, :account_division, :activities

  STATUS_MATCHING =
    {
      "created" => :draft,
      "open" => :open,
      "hold" => :on_hold,
      "closed" => :closed
    }.freeze

  #  /accounts/{account_id}/vacancy_close_reasons
  CLOSE_REASONS = {
    24_431 => "Все наняты",
    24_432 => "Вакансия отменена"
  }.freeze

  # /accounts/{account_id}/vacancy_hold_reasons
  HOLD_REASONS = {
    24_384 => "Заказчик отложил подбор",
    24_385 => "Отмена бюджета"
  }.freeze

  # Total number of jobs: 30
  def self.index
    Huntflow::API.get("accounts/#{Huntflow::API::ACCOUNT_ID}/vacancies")["items"]
                 .map { new(_1.deep_symbolize_keys) }
  end

  def initialize(params)
    @id = params[:id]
    @name = params[:position]
    @created = Time.zone.parse(params[:created]) if params[:created]
    @status = STATUS_MATCHING[params[:state].downcase] if params[:state]
    @account_division = params[:account_division]
  end

  def fetch_activities
    @activities =
      Huntflow::API
      .get("accounts/#{Huntflow::API::ACCOUNT_ID}/vacancies/#{id}/logs")["items"]
      .map { Huntflow::PositionActivity.new(_1.deep_symbolize_keys) }
  end
end
