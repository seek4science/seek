class ChangeIdFieldForAuthorToCreator < ActiveRecord::Migration
  
  def self.up
    rename_column(:assets_creators, :author_id, :creator_id)
  end

  def self.down
    rename_column(:assets_creators, :creator_id, :author_id)
  end

end
