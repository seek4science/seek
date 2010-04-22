class AddDoiToPublications < ActiveRecord::Migration
  def self.up
    add_column :publications, :doi, :string  
  end

  def self.down
    remove_column :publications, :doi
  end
end
