# frozen_string_literal: true

namespace :auth do
  task :setup_account, %i[email] => :environment do |_task, args|
    email = args.fetch(:email)
    puts "Setting up an account for #{email}"
    account = Account.find_or_create_by!(email:, name: email.split("@").first)
    Member.create!(account:, access_level: :admin)
    puts "Account for #{email} was successfully set up!"
  end
end
