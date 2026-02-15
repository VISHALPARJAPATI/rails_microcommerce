class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.text :description
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :products, :name
  end
end
