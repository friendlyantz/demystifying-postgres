require 'pg'

# Configuration for your PostgreSQL database
DB_HOST = 'localhost'
DB_PORT = 5432
DB_NAME = 'index_test'
DB_USER = `whoami`.strip
DB_PASSWORD = 'password'

# Number of transactions you want to run
NUM_TRANSACTIONS = 1_000_000_000

begin
  # Connect to the PostgreSQL database
  conn = PG.connect(
    host: DB_HOST,
    port: DB_PORT,
    dbname: DB_NAME,
    user: DB_USER,
    password: DB_PASSWORD
  )

  # Create a table to perform the inserts if it doesn't exist
  conn.exec('CREATE TABLE IF NOT EXISTS txid_test (id SERIAL PRIMARY KEY, data TEXT);')

  puts "Running #{NUM_TRANSACTIONS} transactions..."

  # Perform the transactions in batches
  NUM_TRANSACTIONS.times do |i|
    conn.transaction do |c|
      # Insert a simple row into the test table
      c.exec("INSERT INTO txid_test (data) VALUES ('Transaction #{i}');")
    end

    # Print progress every 100,000 transactions
    puts "Processed #{i} transactions..." if i % 100_000 == 0
  end
rescue PG::Error => e
  puts "PostgreSQL Error: #{e.message}"
ensure
  # Close the connection
  conn.close if conn
end
