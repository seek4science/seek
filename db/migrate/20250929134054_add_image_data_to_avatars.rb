class AddImageDataToAvatars < ActiveRecord::Migration[7.2]
  def change
    add_column :avatars, :image_data, :text
  end
end
