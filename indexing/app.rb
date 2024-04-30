require 'active_record'
require 'awesome_print'
require 'pg'
require 'progressbar'
require 'colorize'
require 'benchmark'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'index_test',
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

  range = ('AAAA'..'ZZZZ') # 456976 records
  progressbar = ProgressBar.create(
    total: range.count,
    format: "%a %e %P% %b\u{15E7}%i RateOfChange: %r Processed: %c from %C",
    progress_mark: ' ',
    remainder_mark: "\u{FF65}".yellow
  )

  range.each_slice(10_000) do |symbols|
    unindexed_companies = []
    indexed_companies = []

    symbols.each do |symbol|
      name = symbol + 'name'
      exchange = '1234'
      description = symbol + 'description'

      company = {
        name: name,
        exchange: exchange,
        symbol: symbol,
        description: description,
      }

      unindexed_companies << company
      indexed_companies << company

      progressbar.increment
    end

    ActiveRecord::Base.transaction do
      UnindexedCompany.insert_all(unindexed_companies)
      IndexedCompany.insert_all(indexed_companies)
    end
  end
end

def benchmark(symbol = 'ZXUD')
  time_unindexed = Benchmark.realtime do
    UnindexedCompany.find_by(symbol:)
  end
  puts "Time to find in UnindexedCompany: #{time_unindexed * 1000} milliseconds".light_red

  time_indexed = Benchmark.realtime do
    IndexedCompany.find_by(symbol:)
  end
  puts "Time to find in IndexedCompany: #{time_indexed * 1000} milliseconds".red

  puts "IndexedCompany is #{(time_unindexed / time_indexed).round(2)} times faster than UnindexedCompany".green

  time_indexed = Benchmark.realtime do
    IndexedCompany.where('indexed_companies.name ILIKE ?', "#{symbol} nAmE").take
  end
  puts "Time to find in IndexedCompany with ILIKE: #{time_indexed * 1000} milliseconds".yellow

  time_unindexed = Benchmark.realtime do
    UnindexedCompany.where('unindexed_companies.name ILIKE ?', "#{symbol} nAmE").take
  end
  puts "Time to find in UnindexedCompany with ILIKE: #{time_unindexed * 1000} milliseconds".light_yellow

  time_indexed = Benchmark.realtime do
    IndexedCompany.where('indexed_companies.name ILIKE ?', "%#{symbol.next}%").take
  end
  puts "Time to find in IndexedCompany with ILIKE and wildcard: #{time_indexed * 1000} milliseconds".yellow

  time_unindexed = Benchmark.realtime do
    UnindexedCompany.where('unindexed_companies.name ILIKE ?', "%#{symbol.next}%").take
  end
  puts "Time to find in UnindexedCompany with ILIKE and wildcard: #{time_unindexed * 1000} milliseconds".light_yellow
end

benchmark('ZXUD')

binding.irb
