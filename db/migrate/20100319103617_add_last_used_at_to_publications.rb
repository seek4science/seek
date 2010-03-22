class AddLastUsedAtToPublications < ActiveRecord::Migration
  def self.up
    add_column :publications, :last_used_at, :datetime  
  end

  def self.down
    remove_column :publications, :last_used_at
  end
end
