# frozen_string_literal: true

class Interceptors::NormalizeMailerContentInterceptor
  def self.delivering_email(message)
    message.subject = message.subject.unicode_normalize(:nfd)
    message.body = message.body.to_s.unicode_normalize(:nfd)
  end
end
