class AddIndexToCompaniesSearchable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

 def change
 add_index :companies, :searchable, using: :gin, algorithm: :concurrently
 end
 end
