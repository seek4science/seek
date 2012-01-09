class AddModelImageIdToModels < ActiveRecord::Migration
  def self.up
    add_column :models,:model_image_id,:integer
    add_column :model_versions,:model_image_id,:integer

  end

  def self.down
    remove_column :models,:model_image_id
    remove_column :model_versions,:model_image_id
  end
end
