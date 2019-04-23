class AddIdentitiesAssociationToUser < ActiveRecord::Migration[4.2]
  def self.up
      add_column :identities, :user_id, :integer
      add_index 'identities', ['user_id'], :name => 'index_user_id' 
  end

  def self.down
      remove_column :identities, :user_id
  end
end
