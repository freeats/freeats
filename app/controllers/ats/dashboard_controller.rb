# frozen_string_literal: true

class ATS::DashboardController < ApplicationController
  layout "ats/application"

  before_action { @nav_item = :dashboard }
  before_action { authorize! :dashboard }

  def index
    authorize! :dashboard

    @dashboard_positions_grid =
      ATS::DashboardPositionsGrid.new do |scope|
        positions = scope.where(id: nil) if current_member.interviewer?

        if current_member.access_level.in?(%w[admin employee hiring_manager])
          positions =
            scope
            .joins(:hiring_managers)
            .where(positions_hiring_managers: { hiring_manager_id: current_member.id })

          unless current_member.hiring_manager?
            positions =
              positions
              .union(scope.where(positions: { recruiter_id: current_member.id }))
              .union(
                scope
                  .joins(:collaborators)
                  .where(positions_collaborators: { collaborator_id: current_member.id })
              )
          end
        end

        positions
          .with_color_codes
          .order(
            ActiveRecord::Base.sanitize_sql_for_order(
              [
                Arel.sql(
                  <<~SQL
                    id,
                    positions.recruiter_id != ?,
                    color_code ASC
                SQL
                ),
                current_member.id
              ]
            )
          )
      end

    @dashboard_candidates_grid =
      ATS::DashboardCandidatesGrid.new(
        params.fetch(:ats_dashboard_candidates_grid, {})
              .merge(current_member_id: current_member.id)
      ) do |scope|
        scope
          .where(recruiter_id: current_member.id)
          .joins(placements: :position_stage)
          .where(placements: { status: :qualified })
          .where(position_stages: { list_index: 3.. }) # Replied or later
          .order("latest_qualified_stage DESC")
          .group(:id)
          .select(:id, :full_name, :last_activity_at, :recruiter_id, :created_at,
                  "max(position_stages.list_index) AS latest_qualified_stage")
      end
  end
end
