# frozen_string_literal: true

class Public::RecaptchaController < ApplicationController
  def verify
    uri = URI("https://www.google.com/recaptcha/api/siteverify")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    verify_request = Net::HTTP::Post.new(uri.path)
    verify_request.set_form_data("secret" => RecaptchaV3::SECRET_KEY, "response" => params[:token])

    response = https.request(verify_request)

    raise ATS::APIError, "code: #{res.code}, error: #{res}" unless response.is_a?(Net::HTTPSuccess)

    res = JSON.parse(response.body)
    # The incorrect-captcha-sol and browser-error are ignored because we can't fix them.
    unless res["success"]
      if %w[incorrect-captcha-sol browser-error].include?(*res["error-codes"])
        render json: { error: { title: res["error-codes"][0] } },
               status: :unprocessable_entity
        return
      end

      raise ATS::APIError, "code: #{res.code}, error: #{res}"
    end

    render json: res.to_json
  rescue StandardError => e
    ATS::Logger
      .new(where: "Public::RecaptchaController#verify")
      .external_log(
        "Recaptcha verification failed",
        extra: {
          error_message: e
        }
      )
    render json: { error: { title: e.message } }, status: :unprocessable_entity
  end
end
