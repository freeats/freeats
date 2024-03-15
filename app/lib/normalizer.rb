# frozen_string_literal: true

module Normalizer
  def self.email_address(address)
    address.strip.downcase
  end
end
