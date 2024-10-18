# frozen_string_literal: true

require "factory_bot"
require "faker"

FactoryBot.find_definitions

module DevSeeds
  class << self
    include FactoryBot::Syntax::Methods
  end

  def self.seed
    show_help if ARGV - ["-h", "--help"] != ARGV || ARGV.empty?

    ARGV.each do |argument|
      public_send(:"create_#{argument}")
    end
    puts("Done!")
  rescue NoMethodError
    show_help
  end

  def self.show_help
    available_arguments =
      methods(false)
      .map(&:to_s)
      .filter { |method| method.start_with?("create_") }
      .map { |method| method[7..] }

    puts(<<~TEXT)
      This script creates data which is conveniently displayed when testing client profiles.

      To add your own seeds, simply add a method to the file prefixed with `create_`. Keep in
      mind that private methods prefixed with `create` won't be available as arguments.

      Usage: rails runner db/dev_seeds.rb [arguments]

      Available arguments:
          #{available_arguments.join("\n    ")}
    TEXT

    exit
  end

  def self.create_candidates_with_sourced_placements
    position = Position.find_by(name: "Golang developer")
    tenant = position.tenant
    ActsAsTenant.current_tenant = tenant
    100.times do
      Candidate.create!(
        full_name: Faker::Name.name,
        company: Faker::Company.name,
        headline: Faker::Company.catch_phrase
      )
    end

    Candidate.find_each do |candidate|
      Placements::Add.new(
        params: {
          candidate_id: candidate.id,
          position_id: position.id
        },
        create_duplicate_placement: true,
        actor_account: Member.active.sample.account
      ).call.value!
    end
  end
end

DevSeeds.seed
