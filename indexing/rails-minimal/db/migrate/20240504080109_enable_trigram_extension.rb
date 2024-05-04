class EnableTrigramExtension < ActiveRecord::Migration[7.1]
  def change
    enable_extension :pg_trgm # this seems unneccessary with pg_search gem?
  end
end
