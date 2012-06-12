class RemoveModelVersionFromModelImages < ActiveRecord::Migration
  def self.up
    remove_column :model_images,:model_version
  end

  def self.down
    add_column :model_images,:model_version,:integer
  end
end
