class RemoveIdImageFromModels < ActiveRecord::Migration
  def self.up
    execute("SELECT id_image, model_image_id FROM models").each do |id|
      id_image = id[0]
      model_image_id = id[1]
      if id_image && model_image_id.nil?
         raise  Exception.new("Please make sure id_image is copied before removed! try rake task that moves id_image data to model_image")
      end
    end

    remove_column :models,:id_image
    remove_column :model_versions,:id_image
  end

  def self.down
    add_column :models,:id_image,:integer
    add_column :model_versions,:id_image,:integer
  end
end
