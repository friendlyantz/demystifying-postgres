# frozen_string_literal: true

class AddSearchableToCompanies < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE companies
      ADD COLUMN searchable tsvector GENERATED ALWAYS AS (
      setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
      setweight(to_tsvector('english', coalesce(description,'')), 'B')
      ) STORED;
    SQL
  end

  def down
    remove_column :companies, :searchable
  end
end
