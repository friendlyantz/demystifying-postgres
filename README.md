
## Installation

```sh
# cd into dir
rake -T
```

docker script is part of rake, but here it is

```sh
docker run --name demystifying-postgres \
-e POSTGRES_PASSWORD=password \
-e POSTGRES_USER=$(whoami) \
-e POSTGRES_DB=index_test \
-p 5432:5432 \
-d postgres
```

## connect via `psql`


```sh
psql -h localhost -p 5432 -U friendlyantz -d index_test
# password: password
```

or

```sh
createdb -h localhost -U friendlyantz db_name
```

---

# Search

## Some findings

ILIKE with wildcard on both sides vs only on the right side:  little difference. both sides is slower 10-20%
wildcard provided little, to no benefit to ILIKE, however if data after wildcard was more or less identical, it was magnitudes faster. i.e. ABDCSSA-predictable_string_replaced_by_wildcard
Partial index scan (~20%) - provided substantial improvement too, perhaps proportional to the size of the index, but not sure.

```
Time to find by symbol in UnindexedCompany: 111.06999998446554 milliseconds
Time to find by symbol in IndexedCompany: 1.0400000028312206 milliseconds
IndexedCompany is 106.8 times faster than UnindexedCompany

Time to find by symbol in PartialIndexedCompany: 81.54300000751391 milliseconds

Time to find in UnindexedCompany with ILIKE no wildcard: 206.3559999805875 milliseconds
Time to find in UnindexedCompany with ILIKE and wildcard on BOTH sides: 223.65699999500066 milliseconds
Time to find in UnindexedCompany with ILIKE and wildcard ONLY on the RIGHT side: 205.97499998984858 milliseconds
```

Also I noted hitting Partially indexed table second time with the same query (outside index range) was 100x faster, while others did not change (edited)

---

## GIN index for ILIKE

GIN/GIST indexes together with pg_tgrm can
sometimes be used for LIKE and ILIKE, but query
performance is unpredictable when user-generated
input is presented.

yet it was faster 100x than unindexed table

```

Time to find in UnindexedCompany with ILIKE no wildcard: 197.44199997512624 milliseconds
Time to find in GinIndexedCompany with ILIKE no wildcard: 3.2500000088475645 milliseconds
=======  ILIKE by name =========
Time to find in UnindexedCompany with ILIKE and wildcard on BOTH sides: 216.9819999835454 milliseconds
Time to find in GinIndexedCompany with ILIKE and wildcard on BOTH sides: 1.5279999934136868 milliseconds
=======  ILIKE by name =========
Time to find in UnindexedCompany with ILIKE and wildcard ONLY on the RIGHT side: 196.53300003847107 milliseconds
Time to find in GinIndexedCompany with ILIKE and wildcard ONLY on the RIGHT side: 1.340000017080456 milliseconds

```

```ruby
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
```

## Triagram

```sql
SELECT show_trgm('Apple'),
```

---

# Indexing


