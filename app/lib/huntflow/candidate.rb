# frozen_string_literal: true

class Huntflow::Candidate
  attr_reader :id, :name, :created, :skype, :photo_url, :email, :phone,
              :headline, :company, :placements, :activities, :tags, :external_ids

  TAGS = {
    133_703 => "Черный список",
    133_704 => "Рекомендация",
    133_705 => "Резерв"
  }.freeze

  SOURCES = {
    446_786 => "AmazingHiring",
    446_787 => "Artstation",
    446_781 => "Avito",
    446_788 => "Behance",
    446_795 => "Career.habr.com",
    446_789 => "DeviantArt",
    446_791 => "Dribbble",
    446_780 => "Facebook",
    497_403 => "Farpost",
    446_800 => "getmatch отклик",
    446_801 => "getmatch подборки",
    446_777 => "Github",
    446_771 => "HeadHunter",
    446_790 => "JobLab",
    446_774 => "LinkedIn",
    446_792 => "Podbor.io",
    476_505 => "Rabota.by",
    446_784 => "Rabotanur.kz",
    446_797 => "Rabota.ru",
    497_402 => "Response from Farpost.ru",
    458_461 => "Response from Rabota.ru",
    446_776 => "Robota.ua",
    446_773 => "SuperJob",
    446_782 => "VK",
    446_775 => "Work.ua",
    446_793 => "Yandex.Talents",
    446_778 => "Агентство",
    446_783 => "Зарплата.ру",
    446_799 => "Зарплата.ру",
    446_796 => "Отклик с Avito",
    446_772 => "Отклик с HeadHunter",
    446_798 => "Отклик с Huntflow.io",
    476_506 => "Отклик с Rabota.by",
    446_785 => "Отклик с SuperJob",
    446_794 => "Отклик с Хабр карьеры",
    446_779 => "Рекомендация"
  }.freeze

  def self.index(page)
    Huntflow::API.get("accounts/#{Huntflow::API::ACCOUNT_ID}/applicants", { page: })["items"]
                 .map { new(_1.deep_symbolize_keys) }
  end

  # https://api.huntflow.ru/v2/docs#get-/accounts/-account_id-/applicants/-applicant_id-/externals/-external_id-/pdf
  def self.get_resume(candidate_id:, external_id:)
    Huntflow::API.get(
      "accounts/#{Huntflow::API::ACCOUNT_ID}/applicants/#{candidate_id}" \
      "/externals/#{external_id}/pdf"
    )
  end

  def initialize(params)
    @id = params[:id]
    @name = [params[:first_name], params[:middle_name], params[:last_name]].compact_blank.join(" ")
    @headline = params[:position]
    @created = Time.zone.parse(params[:created]) if params[:created]
    @company = params[:company]
    @email = params[:email]
    @phone = params[:phone]
    @money = params[:money]
    @photo_url = params[:photo_url]
    @skype = params[:skype]
    @placements = []
    @tags = params[:tags]
    params[:links]&.each do |placement_params|
      @placements << Huntflow::Placement.new(placement_params)
    end
    @external_ids = params[:external]
  end

  def fetch_activities
    res =
      Huntflow::API.get("accounts/#{Huntflow::API::ACCOUNT_ID}/applicants/#{id}/logs")
                   .deep_symbolize_keys
    @activities = res[:items].map { Huntflow::CandidateActivity.new(_1) }
  end
end
