class DropUseCustomSharingFieldFromPolicy < ActiveRecord::Migration
  def self.up
    remove_column :policies,:use_custom_sharing
  end

  def self.down
    add_column :policies,:use_custom_sharing ,:tinyint,:default=>false
  end
end
