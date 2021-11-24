class AddDataFileToPlaceholders < ActiveRecord::Migration[5.2]
  def change
    add_column :placeholders, :data_file_id, :integer
  end
end
