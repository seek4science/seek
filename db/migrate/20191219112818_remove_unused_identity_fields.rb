class RemoveUnusedIdentityFields < ActiveRecord::Migration[5.2]
  def up
    remove_index :identities, name: :index_identities_on_email
    remove_index :identities, name: :index_identities_on_reset_password_token
    remove_column :identities, :email
    remove_column :identities, :encrypted_password
    remove_column :identities, :reset_password_token
    remove_column :identities, :reset_password_sent_at
    remove_column :identities, :remember_created_at
    remove_column :identities, :token
    remove_column :identities, :expires_at
    remove_column :identities, :expires
  end

  def down
    add_column :identities, :email, :string, default: "", null: false
    add_column :identities, :encrypted_password, :string, default: "", null: false
    add_column :identities, :reset_password_token, :string
    add_column :identities, :reset_password_sent_at, :datetime
    add_column :identities, :remember_created_at, :datetime
    add_column :identities, :token, :string
    add_column :identities, :expires_at, :integer
    add_column :identities, :expires, :boolean
    add_index :identities, :email, unique: true
    add_index :identities, :reset_password_token, unique: true
  end
end
