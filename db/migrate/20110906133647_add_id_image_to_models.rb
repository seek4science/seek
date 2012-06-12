class AddIdImageToModels < ActiveRecord::Migration
  def self.up
    add_column :models, :id_image,:integer
    add_column :model_versions,:id_image,:integer
  end

  def self.down
    remove_column :models,:id_image
    remove_column :model_versions,:id_image
  end
end
