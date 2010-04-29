class AddOtherCreatorsToSops < ActiveRecord::Migration
  def self.up
    add_column :sops, :other_creators, :text
    add_column :sop_versions, :other_creators, :text
  end

  def self.down
    remove_column :sops, :other_creators
    remove_column :sop_versions, :other_creators
  end
end
