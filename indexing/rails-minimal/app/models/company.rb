class Company < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search, against: :description # unscoped / no weights

  pg_search_scope :search,
                  against: { name: 'A', description: 'B' }, # can be 'A', 'B', 'C' or 'D'
                  using: { tsearch: {
                    dictionary: 'english',
                    tsvector_column: 'searchable'
                    } }
end
