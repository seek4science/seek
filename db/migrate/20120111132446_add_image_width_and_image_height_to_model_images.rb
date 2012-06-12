class AddImageWidthAndImageHeightToModelImages < ActiveRecord::Migration
  def self.up
    add_column :model_images,:image_width,:integer
    add_column :model_images,:image_height,:integer
  end

  def self.down
    remove_column :model_images,:image_width,:image_height
  end
end
