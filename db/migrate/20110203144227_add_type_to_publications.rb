class AddTypeToPublications < ActiveRecord::Migration
  def self.up
    add_column :publications,:publication_type,:integer,:default=>1
  end

  def self.down
    remove_column :publications,:publication_type
  end
end
