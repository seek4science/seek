class AddOmniauthToIdentities < ActiveRecord::Migration[4.2]
  def change
    add_column :identities, :provider, :string
    add_column :identities, :uid, :string
    add_column :identities, :token, :string
    add_column :identities, :expires_at, :integer
    add_column :identities, :expires, :boolean
  end
end
