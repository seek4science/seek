class AddOtherCreatorsToModels < ActiveRecord::Migration
  def self.up
    add_column :models, :other_creators, :text
    add_column :model_versions, :other_creators, :text
  end

  def self.down
    remove_column :models, :other_creators
    remove_column :model_versions, :other_creators
  end
end
