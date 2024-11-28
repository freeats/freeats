# frozen_string_literal: true

class EmailMessageSchema < ApplicationSchema
  include EmailRegexp

  define do
    required(:from).filled(:string).maybe(format?: EMAIL_REGEXP)
    required(:to).filled(array[:string]).each(format?: EMAIL_REGEXP)
    optional(:cc).maybe(array[:string]).each(format?: EMAIL_REGEXP)
    optional(:bcc).maybe(array[:string]).each(format?: EMAIL_REGEXP)
    optional(:reply_to).filled(:string).maybe(format?: EMAIL_REGEXP)
    required(:subject).filled(:string)
    required(:html_body).filled(:string)
  end
end
