require 'active_record'
require 'awesome_print'
require 'pg'
require 'faker'
require 'faker/default/company'
require 'progressbar'
require 'colorize'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'index_test',
  username: 'friendlyantz',
  password: 'password',
  host: 'localhost',
  port: 5432
)

conn = PG.connect(
  dbname: 'postgres',
  user: 'friendlyantz',
  password: 'password',
  host: 'localhost', # if you run in dockerm you need to connect via tcp and specify host/post, otherwise it uses unix socket
  port: 5432
)

# begin
#   conn.exec('DROP DATABASE IF EXISTS index_test')
# rescue PG::Error => e
#   puts "An error occurred while trying to drop the database: #{e.message}"
# end

begin
  conn.exec('CREATE DATABASE index_test')
rescue PG::DuplicateDatabase
  puts 'Database index_test already exists.'
end

class CreateUnindexedCompanies < ActiveRecord::Migration[7.1]
  def change
    return if ActiveRecord::Base.connection.table_exists?(:unindexed_companies)

    create_table :unindexed_companies do |t|
      t.string :exchange, null: false
      t.string :symbol, null: false
      t.string :name, null: false
      t.text :description, null: false
      t.timestamps
    end
  end
end

class CreateIndexedCompanies < ActiveRecord::Migration[7.1]
  def change
    return if ActiveRecord::Base.connection.table_exists?(:indexed_companies)

    create_table :indexed_companies do |t|
      t.string :exchange, null: false
      t.string :symbol, null: false
      t.string :name, null: false
      t.text :description, null: false
      t.timestamps

      t.index :symbol
      t.index %(exchange, symbol), unique: true
    end
  end
end

CreateIndexedCompanies.new.migrate(:up)
CreateUnindexedCompanies.new.migrate(:up)

class UnindexedCompany < ActiveRecord::Base
end

class IndexedCompany < ActiveRecord::Base
end

puts "do you want to create reset data? type 'yes'".red
if gets.chomp == 'yes'
  puts 'wiping data...'
  ActiveRecord::Base.connection.execute('TRUNCATE unindexed_companies RESTART IDENTITY CASCADE')
  ActiveRecord::Base.connection.execute('TRUNCATE indexed_companies RESTART IDENTITY CASCADE')
  # these are too slow, use the above instead
  # IndexedCompany.destroy_all
  # UnindexedCompany.destroy_all
  puts 'wipe complete. seeding'

  range = ('AAAA'..'ZZZZ') # 456976
  progressbar = ProgressBar.create(
    total: range.count,
    format: "%a %e %P% %b\u{15E7}%i RateOfChange: %r Processed: %c from %C",
    progress_mark: ' ',
    remainder_mark: "\u{FF65}".yellow
  )

  range.each_slice(10_000) do |symbols|
    ActiveRecord::Base.transaction do
      symbols.each do |symbol|
        name = symbol + 'name'
        exchange = '1234'
        description = symbol + 'description'

        UnindexedCompany.create!(
          name:,
          exchange:,
          symbol:,
          description:
        )

        IndexedCompany.create!(
          name:,
          exchange:,
          symbol:,
          description:
        )

        progressbar.increment
      end
    end
  end
end

require 'benchmark'

symbol = 'YourSymbol' # replace with the symbol you're looking for

time_unindexed = Benchmark.realtime do
  UnindexedCompany.find_by(symbol:)
end
puts "Time to find in UnindexedCompany: #{time_unindexed * 1000} milliseconds".light_red

time_indexed = Benchmark.realtime do
  IndexedCompany.find_by(symbol:)
end
puts "Time to find in IndexedCompany: #{time_indexed * 1000} milliseconds".red

puts "IndexedCompany is #{(time_unindexed / time_indexed).round(2)} times faster than UnindexedCompany".green

binding.irb
