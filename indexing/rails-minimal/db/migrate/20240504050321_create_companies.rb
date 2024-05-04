class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :symbol
      t.string :exchange
      t.text :description

      t.timestamps
    end
  end
end
