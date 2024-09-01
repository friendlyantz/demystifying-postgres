require 'active_record'
require 'awesome_print'
require 'pg'
require 'progressbar'
require 'colorize'
require 'benchmark'
require 'pg_search'

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
  include PgSearch::Model
  # pg_search_scope :search, against: :description # unscoped / no weights
  pg_search_scope :search,
                  against: { name: 'A', description: 'B' }, # can be 'A', 'B', 'C' or 'D'
                  using: { tsearch: { dictionary: 'english' } }
end

class IndexedCompany < ActiveRecord::Base
end

class PartialIndexedCompany < ActiveRecord::Base
end

class GinIndexedCompany < ActiveRecord::Base
  scope :name_similar,
        lambda { |name|
          quoted_name = ActiveRecord::Base.connection.quote_string(name)
          where('gin_indexed_companies.name % :name', name:).order(
            Arel.sql("similarity(gin_indexed_companies.name, '#{quoted_name}') DESC")
          )
        }
end

puts "do you want to reset DB? type 'yes' (RECOMMENDED to do it regularly to reset cache)".red
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
  ActiveRecord::Base.connection.execute('TRUNCATE gin_indexed_companies RESTART IDENTITY CASCADE')
  # IndexedCompany.destroy_all # these are too slow, use the above instead
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
    companies = []

    symbols.each do |symbol|
      name = Faker::Company.unique.name
      exchange = "#{rand(0.00..100.00).round(2)}%"
      description = Faker::Company.bs

      companies << { name:, exchange:, symbol:, description: }

      progressbar.increment
    end

    ActiveRecord::Base.transaction do
      UnindexedCompany.insert_all(companies)
      IndexedCompany.insert_all(companies)
      PartialIndexedCompany.insert_all(companies)
      GinIndexedCompany.insert_all(companies)
    end
  end

  UnindexedCompany.create!(name: 'Melbourne', exchange: '1.00%', symbol: 'MELBS',
                           description: 'the weather in Melbourne is known for its variability as well as predictability')
  UnindexedCompany.create!(name: 'Auckland', exchange: '0.10%', symbol: 'AUCKL',
                           description: 'the variable weather in Auckland is not as predictable as in Melbourne')
end

def benchmark_like(symbol = 'ZXUD')
  time_unindexed = Benchmark.realtime { UnindexedCompany.find_by(symbol:) }
  puts "Time to find by symbol in UnindexedCompany: #{time_unindexed * 1_000_000} microseconds".light_red

  time_indexed = Benchmark.realtime { IndexedCompany.find_by(symbol:) }
  puts "Time to find by symbol in IndexedCompany: #{time_indexed * 1_000_000} microseconds".red

  puts "IndexedCompany is #{(time_unindexed / time_indexed).round(2)} times faster than UnindexedCompany".green

  time_partial_indexed = Benchmark.realtime { PartialIndexedCompany.find_by(symbol:) }
  puts "Time to find by symbol in PartialIndexedCompany: #{time_partial_indexed * 1_000_000} microseconds".red

  puts "Partial index was slower than full index by #{(time_partial_indexed / time_indexed).round(2)} times".light_green

  puts '='.red * 50
end

def measure(code)
  query = -> { eval(code) }
  # take to avoid loading all records, but it increases time, not sure why,
  # as it is supposed to be similar to limi(1),
  # but applicable to ruby arrays as well as AR relations
  time_indexed = Benchmark.realtime { query.call }

  puts code
  puts query.call.to_sql
  puts "time used: #{(time_indexed * 1_000_000).round(2)} microseconds".light_blue
  puts '-' * 50
end

def benchmark_ilike(name = 'Friendlyantz')
  puts "compare GinIndexedCompany with trigrams for searchterm: #{name}".purple
  puts ' ILIKE no Wildcard'.light_green
  measure "UnindexedCompany.where('unindexed_companies.name ILIKE ?', \"#{name}\")"
  measure "GinIndexedCompany.where('gin_indexed_companies.name ILIKE ?', \"#{name}\")"

  puts ' ILIKE with wildcard on BOTH sides'.light_green
  measure "UnindexedCompany.where('unindexed_companies.name ILIKE ?', \"%#{name}%\")"
  measure "GinIndexedCompany.where('gin_indexed_companies.name ILIKE ?', \"%#{name}%\")"

  puts '  =======  ILIKE by name  with wildcard on the right ========='.light_green
  measure "UnindexedCompany.where('unindexed_companies.name ILIKE ?', \"#{name}%\")"
  measure("GinIndexedCompany.where('gin_indexed_companies.name ILIKE ?', \"#{name}%\")")

  result = IndexedCompany.where('indexed_companies.name ILIKE ?', "%#{name}%").take || 'nothing found'
  puts result.inspect.red
end

puts '--------- outside partial index indexed ------------------------'
benchmark_like('ZXUD')
puts '--------- within partial index indexed ------------------------'
benchmark_like('DITO')

benchmark_ilike('Non existent record forcind to do full scan') # non-existent reocrd
benchmark_ilike('short string') # non-existent reocrd
benchmark_ilike('Will') # non-existent reocrd

ap UnindexedCompany.search('Melbourne predictable')
binding.irb
