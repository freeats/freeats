# frozen_string_literal: true

class ATS::EmailThreadsController < ApplicationController
  include Dry::Monads[:result]

  def fetch_messages
    email_thread = EmailThread.find(params[:email_thread_id])
    collection =
      EmailMessage
      .with_addresses
      .where(email_thread_id: email_thread.id)
      .preload(:events)
      .order(timestamp: :desc)
    payload = render_to_string(
      collection,
      locals: {
        hashed_avatars: {},
        candidate_ids: params[:candidate_ids],
        controller_name: params[:controller_name]
      }
    )
    render(
      turbo_stream: turbo_stream.replace(
        helpers.dom_id(email_thread),
        payload
      ),
      status: :accepted
    )
  end
end
