# frozen_string_literal: true

class Settings::Recruitment::Sources::Change < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :actor_account, Types::Instance(Account).optional
  option :candidate_sources_params,
         Types::Strict::Array.of(
           Types::Strict::Hash.schema(
             id?: Types::Strict::String,
             name: Types::Strict::String
           )
         )

  def call
    new_sources, sources_for_deleting =
      yield prepare_sources(candidate_sources_params)

    CandidateSource.transaction do
      yield destroy_candidate_source(sources_for_deleting:, actor_account:)
      yield save_candidate_source(new_sources)
    end

    Success()
  end

  private

  def destroy_candidate_source(sources_for_deleting:, actor_account:)
    return Success() if sources_for_deleting.blank?

    candidates =
      Candidate.where(candidate_source_id: sources_for_deleting.map(&:id))
    candidates.each do |candidate|
      Candidates::Change.new(
        candidate:, actor_account:, params: { source: "" }
      ).call
    end

    sources_for_deleting.map(&:reload).each(&:destroy!)
    Success()
  rescue StandardError => e
    Failure[:deletion_failed, e]
  end

  def prepare_sources(candidate_sources_params)
    old_sources = CandidateSource.all

    new_sources = candidate_sources_params.map do |new_source|
      name = new_source[:name]
      id = new_source[:id]

      if id.blank?
        CandidateSource.new(name:)
      else
        source = CandidateSource.find(id)

        if source.name == "LinkedIn" && name != "LinkedIn" ||
           source.name != "LinkedIn" && name == "LinkedIn"
          return Failure[:linkedin_source_cannot_be_changed]
        elsif source.name == "LinkedIn" && name == "LinkedIn"
          source
        else
          source.name = name
          source
        end
      end
    end

    sources_for_deleting = old_sources.filter do |source|
      new_sources.pluck(:id).exclude?(source.id)
    end
    if sources_for_deleting.any? { _1.name == "LinkedIn" }
      return Failure[:linkedin_source_cannot_be_changed]
    end

    Success[new_sources, sources_for_deleting]
  rescue ActiveRecord::RecordNotFound => e
    Failure[:candidate_source_not_found, e]
  end

  def save_candidate_source(candidate_source)
    candidate_source.map(&:save!)

    Success()
  rescue StandardError => e
    Failure[:invalid_sources, e]
  end
end
