# frozen_string_literal: true

class ApplicationController < ActionController::Base
  add_flash_types :warning

  private

  # def render_turbo_stream(streams, notice: nil, warning: nil, error: nil, alerts: [], status: :ok)
  def render_turbo_stream(streams, status: :ok)
    stream_array = Array(streams).compact
    # TODO: Remove if there will be no alerts.
    # alert =
    #   if error.present? then { text: error, type: :error }
    #   elsif warning.present? then { text: warning, type: :warning }
    #   elsif notice.present? then { text: notice, type: :notice }
    #   end
    # alerts << alert if alert
    # # If alerts have been passed, we render them,
    # # else an empty turbo stream that removes all alerts from the page.
    # stream_array.push(
    #   if alerts.present?
    #     turbo_stream.replace("alerts", partial: "layouts/ats/alert", locals: { alerts: })
    #   else
    #     turbo_stream.update("alerts", "")
    #   end
    # )
    render turbo_stream: stream_array, status:
  end

  def current_account
    rodauth.rails_account
  end
  helper_method :current_account
end
