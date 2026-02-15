class AddJtiToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :jti, :string
    add_index :users, :jti, unique: true

    # Backfill existing users so we can set NOT NULL
    reversible do |dir|
      dir.up do
        User.reset_column_information
        User.find_each { |u| u.update_column(:jti, SecureRandom.uuid) }
        change_column_null :users, :jti, false
      end
    end
  end
end
