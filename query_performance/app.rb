require 'pg'

# Configuration for your PostgreSQL database
DB_HOST = 'localhost'
DB_PORT = 5432
DB_NAME = 'index_test'
DB_USER = `whoami`.strip
DB_PASSWORD = 'password'

# Connect to the PostgreSQL database
conn = PG.connect(
  host: DB_HOST,
  port: DB_PORT,
  dbname: DB_NAME,
  user: DB_USER,
  password: DB_PASSWORD
)

puts 'Do you want to create and seed the table? (y/N)'
if gets.chomp == 'y'
  conn.exec('DROP TABLE IF EXISTS product_data')
  conn.exec(
    <<~SQL
      CREATE TABLE product_data (id bigserial primary key, user_id text, organization_id text, data jsonb);
    SQL
  )
  seed_query_and_add_index_on_user_id = <<~SQL
    INSERT INTO product_data(user_id, organization_id, data) SELECT user_id, gen_random_uuid()
    AS organization_id, jsonb_build_object('subscribed', random() > 0.5)
    AS data FROM generate_series(1, 100000) user_id;
    CREATE INDEX ON product_data(user_id);
  SQL

  conn.exec(seed_query_and_add_index_on_user_id)

  puts 'creating product_events table and index'
  conn.exec(
    <<~SQL
      CREATE TABLE product_events(organization_id text, occurred_at timestamptz, event_value bigint);
      CREATE INDEX ON product_events(organization_id);
    SQL
  )
  puts 'generate a lot of data for each organization:'
  conn.exec(
    <<~SQL
      INSERT INTO product_events(organization_id, occurred_at, event_value)
      SELECT d.organization_id, occurred_at, random() * 100
      FROM (SELECT DISTINCT organization_id FROM product_data
      LIMIT 100) d, generate_series('2000-01-01'::timestamptz, '2010-01-01'::timestamptz, '1 hour') occurred_at;
    SQL
  )
  puts 'generate a lot of data for each organization: COMPLETE'
  conn.close
end
