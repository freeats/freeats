# frozen_string_literal: true

class ApplicationOperation
  extend Dry::Initializer

  option :logger, Types::Instance(ATS::Logger),
         default: -> { ATS::Logger.new(where: self.class.to_s) }
end
