class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :total_cents, null: false
      t.string :status, null: false, default: "pending"
      t.string :stripe_session_id
      t.json :line_items

      t.timestamps
    end
    add_index :orders, :stripe_session_id, unique: true
  end
end
