# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ErrorHandler

  add_flash_types :warning

  private

  def render_turbo_stream(streams, notice: nil, warning: nil, error: nil, alerts: [], status: :ok)
    stream_array = Array(streams).compact
    alert =
      if error.present? then { text: error, type: :error }
      elsif warning.present? then { text: warning, type: :warning }
      elsif notice.present? then { text: notice, type: :notice }
      end
    alerts << alert if alert
    # If alerts have been passed, we render them,
    # else an empty turbo stream that removes all alerts from the page.
    stream_array.push(
      if alerts.present?
        turbo_stream.replace("alerts", partial: "layouts/ats/alert", locals: { alerts: })
      else
        turbo_stream.update("alerts", "")
      end
    )
    render turbo_stream: stream_array, status:
  end

  def current_account
    rodauth.rails_account
  end

  def current_member
    @current_member ||= current_account&.member
  end
  helper_method :current_account, :current_member
end
