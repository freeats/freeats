# frozen_string_literal: true

# This script reads data from the csv file and
# creates records in the DB for the model which was passed.
# Columns in csv file should have the same name as the model's fields.
# This script is useful when need to add data from production to development.

# How to use:
# 1. Prepare csv file, for example, export it from the Metabase.
# 2. Run this command from the root of the application and pass necessary arguments.
# rails runner import_from_csv.rb <csv_path> <model_name>
# <csv_path> - path to csv file.
# <model_name> - ActiveRecord model name. (example: "Person", "SkillTag")
#
# Example to run:
# rails runner scripts/import_from_csv/import_from_csv.rb ~/Downloads/candidates.csv Candidate

require "csv"

if ARGV.length < 2
  puts "Wrong arguments..."
  puts "Usage: rails runner import_from_csv.rb <csv_path> <model_name>"
  exit 1
end

csv_path = ARGV[0]
model_name = ARGV[1]

items = []

t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

model_default_columns = Object.const_get(model_name).column_defaults

CSV.foreach(csv_path, headers: true) do |row|
  item = row.to_h

  item.map do |key, value|
    item[key] = model_default_columns[key] || "" if value.nil?
  end

  items << item
end
# rubocop:disable Rails/SkipsModelValidations
Object.const_get(model_name).insert_all(items)
# rubocop:enable Rails/SkipsModelValidations

puts "Importing took #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0).round(2)} seconds"
