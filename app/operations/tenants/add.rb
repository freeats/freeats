# frozen_string_literal: true

class Tenants::Add < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :company_name, Types::Strict::String

  def call
    tenant = Tenant.new(name: company_name)
    ActiveRecord::Base.transaction do
      yield save_tenant(tenant)
      create_mandatory_disqualify_reasons(tenant)
    end

    Success(tenant)
  end

  private

  def save_tenant(tenant)
    tenant.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:tenant_invalid, tenant.errors.full_messages.presence || e.to_s]
  end

  def create_mandatory_disqualify_reasons(tenant)
    %w[no_reply position_closed].each do |title|
      DisqualifyReason.create!(
        tenant_id: tenant.id,
        title: title.humanize,
        description: I18n.t("candidates.disqualification.disqualify_statuses.#{title}")
      )
    end
  end
end
