class AddPositionToAssays < ActiveRecord::Migration[5.2]
  def change
    add_column :assays, :position, :integer, unique: true
  end
end
