class RenameIdentitiesUserIdIndex < ActiveRecord::Migration[5.2]
  def change
    rename_index :identities, :index_user_id, :index_identities_on_user_id
  end
end
