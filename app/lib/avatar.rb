# frozen_string_literal: true

module Avatar
  extend ActiveSupport::Concern

  included do
    has_one_attached :avatar do |attachable|
      attachable.variant(:icon, resize_to_fill: [144, 144], preprocessed: true)
      attachable.variant(:medium, resize_to_fill: [450, 450], preprocessed: true)
    end
  end
end
