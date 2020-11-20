class AddIndexForProviderAndUidToIdentities < ActiveRecord::Migration[5.2]
  def change
    add_index :identities, [:provider, :uid]
  end
end
