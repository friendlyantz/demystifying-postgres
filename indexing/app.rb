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
class UnindexedCompany < ActiveRecord::Base
end

class IndexedCompany < ActiveRecord::Base
end

class PartialIndexedCompany < ActiveRecord::Base
end

class GinIndexedCompany < ActiveRecord::Base
end

puts "do you want to reset DB? type 'yes'".red
if gets.chomp == 'yes'
  begin
    conn.exec('DROP DATABASE IF EXISTS index_test')
  rescue PG::Error => e
    puts "An error occurred while trying to drop the database: #{e.message}"
  end

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

  class CreatePartialIndexedCompanies < ActiveRecord::Migration[7.1]
    def change
      return if ActiveRecord::Base.connection.table_exists?(:partial_indexed_companies)

      create_table :partial_indexed_companies do |t|
        t.string :exchange, null: false
        t.string :symbol, null: false
        t.string :name, null: false
        t.text :description, null: false
        t.timestamps

        t.index :symbol, unique: true, where: 'symbol <= \'E\'', name: 'index_on_symbol'
        t.index %i[exchange symbol], unique: true, where: 'symbol <= \'E\'', name: 'index_on_exchange_and_symbol'
      end
    end
  end

  class EnablePgTrgmExtension < ActiveRecord::Migration[7.1]
    def change
      enable_extension 'pg_trgm'
    end
  end

  EnablePgTrgmExtension.new.migrate(:up)

  class CreateGinIndexedCompanies < ActiveRecord::Migration[7.1]
    def change
      return if ActiveRecord::Base.connection.table_exists?(:gin_indexed_companies)

      disable_ddl_transaction

      create_table :gin_indexed_companies do |t|
        t.string :exchange, null: false
        t.string :symbol, null: false
        t.string :name, null: false
        t.text :description, null: false
        t.timestamps

        t.index :name, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently, name: 'index_on_name_trgm'
      end
    end
  end

  CreateIndexedCompanies.new.migrate(:up)
  CreateUnindexedCompanies.new.migrate(:up)
  CreatePartialIndexedCompanies.new.migrate(:up)
  CreateGinIndexedCompanies.new.migrate(:up)

  puts 'wiping data...'
  ActiveRecord::Base.connection.execute('TRUNCATE unindexed_companies RESTART IDENTITY CASCADE')
  ActiveRecord::Base.connection.execute('TRUNCATE indexed_companies RESTART IDENTITY CASCADE')
  ActiveRecord::Base.connection.execute('TRUNCATE partial_indexed_companies RESTART IDENTITY CASCADE')
  # these are too slow, use the above instead
  # IndexedCompany.destroy_all
  puts 'wipe complete. seeding'

  require 'faker'
  require 'faker/default/company'

  range = ('AAAA'..'ZZZZ') # 456976 records
  progressbar = ProgressBar.create(
    total: range.count,
    format: "%a %e %P% %b#{"\u{15E7}".yellow}%i RateOfChange: %r Processed: %c from %C",
    progress_mark: ' ',
    remainder_mark: "\u{FF65}".light_green
  )

  range.each_slice(10_000) do |symbols|
    unindexed_companies = []
    indexed_companies = []

    symbols.each do |symbol|
      name = Faker::Company.unique.name
      exchange = "#{rand(0.00..100.00).round(2)}%"
      description = Faker::Company.bs

      company = {
        name:,
        exchange:,
        symbol:,
        description:
      }

      unindexed_companies << company
      indexed_companies << company

      progressbar.increment
    end

    ActiveRecord::Base.transaction do
      UnindexedCompany.insert_all(unindexed_companies)
      IndexedCompany.insert_all(indexed_companies)
      PartialIndexedCompany.insert_all(indexed_companies)
      GinIndexedCompany.insert_all(indexed_companies)
    end
  end
end

def benchmark(symbol = 'ZXUD')
  time_unindexed = Benchmark.realtime do
    UnindexedCompany.find_by(symbol:)
  end
  puts "Time to find by symbol in UnindexedCompany: #{time_unindexed * 1000} milliseconds".light_yellow

  time_indexed = Benchmark.realtime do
    IndexedCompany.find_by(symbol:)
  end
  puts "Time to find by symbol in IndexedCompany: #{time_indexed * 1000} milliseconds".red

  puts "IndexedCompany is #{(time_unindexed / time_indexed).round(2)} times faster than UnindexedCompany".green

  time_indexed = Benchmark.realtime do
    PartialIndexedCompany.find_by(symbol:)
  end
  puts "Time to find by symbol in PartialIndexedCompany: #{time_indexed * 1000} milliseconds".purple

  puts '=======  ILIKE by Name ========='.yellow
  # ILIKE
  time_unindexed = Benchmark.realtime do
    UnindexedCompany.where('unindexed_companies.name ILIKE ?', "#{symbol.downcase}").take
  end
  puts "Time to find in UnindexedCompany with ILIKE no wildcard: #{time_unindexed * 1000} milliseconds".yellow

  time_indexed = Benchmark.realtime do
    PartialIndexedCompany.where('partial_indexed_companies.name ILIKE ?', "#{symbol.downcase}").take
  end
  puts "Time to find in PartialIndexedCompany with ILIKE no wildcard: #{time_indexed * 1000} milliseconds".purple

  time_indexed = Benchmark.realtime do
    GinIndexedCompany.where('gin_indexed_companies.name ILIKE ?', "#{symbol.downcase}").take
  end
  puts "Time to find in GinIndexedCompany with ILIKE no wildcard: #{time_indexed * 1000} milliseconds".light_blue

  # ILIKE with wildcard on BOTH sides
  puts '=======  ILIKE by name ========='.yellow
  time_indexed = Benchmark.realtime do
    UnindexedCompany.where('unindexed_companies.name ILIKE ?', "%#{symbol}%").take
  end
  puts "Time to find in UnindexedCompany with ILIKE and wildcard on BOTH sides: #{time_indexed * 1000} milliseconds".light_yellow

  time_indexed = Benchmark.realtime do
    GinIndexedCompany.where('gin_indexed_companies.name ILIKE ?', "%#{symbol}%").take
  end
  puts "Time to find in GinIndexedCompany with ILIKE and wildcard on BOTH sides: #{time_indexed * 1000} milliseconds".light_blue

  puts '=======  ILIKE by name ========='.yellow
  # ILIKE with wildcard on the RIGHT side
  time_unindexed = Benchmark.realtime do
    UnindexedCompany.where('unindexed_companies.name ILIKE ?', "#{symbol}%").take
  end
  puts "Time to find in UnindexedCompany with ILIKE and wildcard ONLY on the RIGHT side: #{time_unindexed * 1000} milliseconds".light_yellow

  time_indexed = Benchmark.realtime do
    GinIndexedCompany.where('gin_indexed_companies.name ILIKE ?', "#{symbol}%").take
  end
  puts "Time to find in GinIndexedCompany with ILIKE and wildcard ONLY on the RIGHT side: #{time_indexed * 1000} milliseconds".light_blue
end

benchmark('ZXUD')
puts '---------------------------------'
benchmark('DITO')

binding.irb
