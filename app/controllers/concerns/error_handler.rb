# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  def render403
    message = "Unauthorized"
    status = :forbidden
    respond_to do |format|
      format.html do
        render "errors/403", layout: "ats/application", status:
      end
      format.json do
        render json: { error: { title: message } }, status:
      end
      format.turbo_stream do
        render(
          turbo_stream: turbo_stream.replace(
            :alerts,
            partial: "layouts/ats/alert",
            locals: { text: message, type: :error }
          ),
          status:
        )
      end
      format.js do
        render(
          json: {
            alert: render_to_string(
              partial: "layouts/ats/alert",
              locals: {
                text: message,
                type: :error
              }
            )
          },
          status:,
          content_type: "application/json"
        )
      end
      format.all do
        render plain: "Unsupported format", status:
      end
    end
  end

  def render404
    message = "Page Not Found"
    status = :not_found
    respond_to do |format|
      format.html do
        render "errors/404", layout: "ats/application", status:
      end
      format.json do
        render json: { error: { title: message } }, status:
      end
      format.turbo_stream do
        render(
          turbo_stream: turbo_stream.replace(
            :alerts,
            partial: "layouts/ats/alert",
            locals: { text: message, type: :error }
          ),
          status:
        )
      end
      format.js do
        render(
          json: {
            alert: render_to_string(
              partial: "layouts/ats/alert",
              locals: {
                text: message,
                type: :error
              }
            )
          },
          status:,
          content_type: "application/json"
        )
      end
      format.all do
        render plain: "Unsupported format", status:
      end
    end
  end

  def render422
    message = "The change you wanted was rejected"
    status = :unprocessable_entity
    respond_to do |format|
      format.html do
        render "errors/422", layout: "ats/application", status:
      end
      format.json do
        render json: { error: { title: message } }, status:
      end
      format.turbo_stream do
        render(
          turbo_stream: turbo_stream.replace(
            :alerts,
            partial: "layouts/ats/alert",
            locals: { text: message, type: :error }
          ),
          status:
        )
      end
      format.js do
        render(
          json: {
            alert: render_to_string(
              partial: "layouts/ats/alert",
              locals: {
                text: message,
                type: :error
              }
            )
          },
          status:,
          content_type: "application/json"
        )
      end
      format.all do
        render plain: "Unsupported format", status: :not_found
      end
    end
  end

  def render500
    message = "Application Error."
    status = :internal_server_error
    respond_to do |format|
      format.html do
        render "errors/500", layout: false, status:
      end
      format.json do
        render json: { error: { title: message } }, status:
      end
      format.turbo_stream do
        render(
          turbo_stream: turbo_stream.replace(
            :alerts,
            partial: "layouts/ats/alert",
            locals: { text: message, type: :error }
          ),
          status:
        )
      end
      format.js do
        render(
          json: {
            alert: render_to_string(
              partial: "layouts/ats/alert",
              locals: {
                text: message,
                type: :error
              }
            )
          },
          status:,
          content_type: "application/json"
        )
      end
      format.all do
        render plain: "Unsupported format", status: :not_found
      end
    end
  end

  def render_error(
    messages,
    redirect_url: request.referer,
    status: :bad_request,
    fallback_location: root_path
  )
    if Rails.env.test?
      respond_to do |format|
        error_message = {
          message: messages,
          redirect_url: redirect_url.presence || fallback_location,
          status:,
          fallback_location:
        }
        format.html do
          raise ::RenderErrorExceptionForTests, error_message.merge(format: :html).to_json
        end
        format.json do
          raise ::RenderErrorExceptionForTests, error_message.merge(format: :json).to_json
        end
        format.turbo_stream do
          raise ::RenderErrorExceptionForTests, error_message.merge(format: :turbo_stream).to_json
        end
        format.js do
          raise ::RenderErrorExceptionForTests, error_message.merge(format: :js).to_json
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to redirect_url.presence || fallback_location, alert: messages }
        format.json { render json: { error: { title: Array(messages).join(", ") } }, status: }
        format.turbo_stream do
          render(
            turbo_stream: turbo_stream.replace(
              :alerts,
              partial: "layouts/ats/alert",
              locals: { text: messages, type: :error }
            ),
            status:
          )
        end
        format.js do
          render(
            json: {
              alert: render_to_string(
                partial: "layouts/ats/alert",
                locals: {
                  text: messages,
                  type: :error
                }
              )
            },
            status:,
            content_type: "application/json"
          )
        end
        format.all do
          render plain: "Unsupported format", status: :not_found
        end
      end
    end
  end
end
