# frozen_string_literal: true

namespace :auth do
  # Documented 👍
  task :setup_account, %i[email] => :environment do |_task, args|
    email = args.fetch(:email)
    puts "Setting up an account for #{email}"
    account = Account.find_or_create_by!(email:, name: email.split("@").first)
    Member.create!(account:, access_level: :admin)
    puts "Account for #{email} was successfully set up!"
  end

  task gen_accounts: :environment do
    puts "Generating accounts with random names and emails"
    count = 0
    "abcdefgh".chars.permutation.each_slice(1000) do |array_of_array_of_letters|
      count += array_of_array_of_letters.size

      sql = array_of_array_of_letters.map do |array_of_letters|
        name = array_of_letters.join
        <<~SQL
          WITH account_id AS (
            INSERT INTO accounts (name, email)
            VALUES ('#{name}', '#{name}@mail.com') RETURNING id
          )
          INSERT INTO members (account_id, access_level, created_at, updated_at)
          VALUES ((SELECT id FROM account_id), 'admin', now(), now());
        SQL
      end.join("\n")
      ActiveRecord::Base.connection.execute(sql)
    end
    puts "Successfully generated #{count} accounts and members"
  end
end
