# frozen_string_literal: true

class Sequences::Add
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      member_email_address: Types.Instance(Member::EmailAddress),
      sequence_template: Types.Instance(SequenceTemplate),
      placement: Types.Instance(Placement),
      to: Types::Strict::String,
      parameters: Types::Strict::Hash.default { {} }
    )
    option :actor_account, Types.Instance(Account)
  end

  def call
    yield verify_token(params[:member_email_address])

    to = params[:to]
    yield verify_recipient(to)

    recipient_emails = params[:placement].candidate.all_emails(status: :current) | [to]
    yield check_running_sequences(recipient_emails)

    variables =
      yield compose_variables(
        sequence_template: params[:sequence_template],
        placement: params[:placement],
        actor_account:
      )

    params[:scheduled_at] = Time.zone.now
    params[:status] = :running
    params[:data] = params[:sequence_template].build_sequence_data(variables)

    sequence = Sequence.new(params)

    ActiveRecord::Base.transaction do
      yield save_sequence(sequence)
      yield add_event(sequence:, actor_account:)
    end

    Success(sequence)
  end

  private

  def verify_token(member_email_address)
    if member_email_address.token.blank?
      Failure[:token_is_blank, "Token is blank for #{member_email_address.address}."]
    else
      Success()
    end
  end

  def verify_recipient(email)
    blacklist_candidate = Candidate.search_by_emails(email).where(blacklisted: true).first

    return Success() if blacklist_candidate.blank?

    error = "Sequence can't be sent for <a href=#{blacklist_candidate.url}>" \
            "#{blacklist_candidate.full_name}</a> marked as Blacklisted."
    Failure[:blacklisted_candidate, error]
  end

  def check_running_sequences(recipient_emails)
    if Sequence.to_stop(recipient_emails.uniq).exists?
      error = "There's already a running sequence for #{recipient_emails.sort.join(', ')}."
      return Failure[:running_sequence, error]
    end

    Success()
  end

  def compose_variables(sequence_template:, placement:, actor_account:)
    addition_attr = { position: placement.position, candidate: placement.candidate }

    variables =
      LiquidTemplate.extract_attributes_from(
        current_account: actor_account,
        **addition_attr
      )

    missing_variables = sequence_template.missing_variables(variables)

    if missing_variables.present?
      error = "Missing required sequence template variables: " \
              "#{missing_variables.map { "{{#{_1}}}" }.join(', ')}."
      return Failure[:missing_variables, error]
    end

    Success(variables)
  end

  def save_sequence(sequence)
    sequence.save!
    Success(sequence)
  rescue ActiveRecord::RecordNotUnique => e
    Failure[:sequence_invalid, e.to_s]
  rescue ActiveRecord::RecordInvalid
    Failure[:sequence_invalid, sequence.errors.full_messages]
  end

  def add_event(sequence:, actor_account:)
    params = {
      actor_account:,
      type: :sequence_initialized,
      eventable: sequence
    }

    yield Events::Add.new(params:).call

    Success()
  end
end
