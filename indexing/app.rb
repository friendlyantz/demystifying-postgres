require 'active_record'
# require 'awesome_print'
require 'pg'
require 'progressbar'
require 'colorize'
require 'benchmark'
# require 'pg_search'
require 'faker'
require 'securerandom'

DB_NAME = 'effective_indexing'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: DB_NAME,
  username: `whoami`.strip,
  password: 'password',
  host: 'localhost',
  port: 5432
)

conn = PG.connect(
  dbname: 'postgres',
  user: `whoami`.strip,
  password: 'password',
  host: 'localhost', # if you run in docker you need to connect via tcp and specify host/port, otherwise it uses unix socket
  port: 5432
)

class Company < ActiveRecord::Base
end

puts "do you want to reset DB? type 'yes' (RECOMMENDED to do it regularly to reset cache)".red
if gets.chomp == 'yes'
  begin
    conn.exec("DROP DATABASE IF EXISTS #{DB_NAME}")
  rescue PG::Error => e
    puts "An error occurred while trying to drop the database: #{e.message}"
  end

  begin
    conn.exec("CREATE DATABASE #{DB_NAME}")
  rescue PG::DuplicateDatabase
    puts "Database #{DB_NAME} already exists."
  end

  class CreateCompanies < ActiveRecord::Migration[7.1]
    def change
      return if ActiveRecord::Base.connection.table_exists?(:companies)

      create_table :companies do |t|
        t.integer :price, null: false
        t.jsonb :description, null: false
        t.timestamps
      end
    end
  end

  CreateCompanies.new.migrate(:up)

  puts 'wiping data...'
  ActiveRecord::Base.connection.execute('TRUNCATE companies RESTART IDENTITY CASCADE')
  # IndexedCompany.destroy_all # this is too slow, use the above instead
  puts 'wipe complete. seeding'

  require 'faker'
  require 'faker/default/company'

  records_count = 1_000_000
  progressbar = ProgressBar.create(
    total: records_count,
    format: "%a %e %P% %b#{"\u{15E7}".yellow}%i RateOfChange: %r Processed: %c from %C",
    progress_mark: ' ',
    remainder_mark: "\u{FF65}".light_green
  )

  (0..records_count).step(10_000) do |_offset|
    companies = []

    10_000.times do |_i|
      price = "#{rand(100..999)}%"

      description =
        SecureRandom.alphanumeric(3)
      #   {
      #   "#{SecureRandom.alphanumeric(3)}" => Faker::Company.bs
      # }.to_json

      companies << { price:, description: }
      progressbar.increment
    end

    ActiveRecord::Base.transaction do
      Company.insert_all(companies)
    end
  end
end

binding.irb if $PROGRAM_NAME == __FILE__ && $DEBUG
