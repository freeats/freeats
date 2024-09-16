# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  extend Dry::Initializer

  option :additional_options, Types::Strict::Hash, optional: true

  # Extracts keyword arguments that are not initialized via "option"
  # and stores them in "additional_options".
  def initialize(*, **kwargs)
    @additional_options = kwargs.except(*self.class.dry_initializer.attributes(self).keys)
    super(*, **kwargs.except(*@additional_options.keys))
  end
end
