class AddUuidToPublications < ActiveRecord::Migration
  def self.up
    add_column :publications, :uuid, :string
  end

  def self.down
    remove_column :publications,:uuid
  end
end
