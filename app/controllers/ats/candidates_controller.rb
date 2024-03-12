# frozen_string_literal: true

class Ats::CandidatesController < ApplicationController
  def show
    @candidate = Candidate.find(params[:id])

    render :show
  end

  def update
    @candidate = Candidate.find(params[:id])

    @candidate.avatar.attach(candidate_params[:avatar]) if candidate_params[:avatar].present?
    @candidate.avatar.purge if candidate_params[:remove_avatar].present?

    redirect_to "/"
  end

  private

  def candidate_params
    params.require(:candidate).permit(:avatar, :remove_avatar)
  end
end
