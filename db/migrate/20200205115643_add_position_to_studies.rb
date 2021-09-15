class AddPositionToStudies < ActiveRecord::Migration[5.2]
  def change
    add_column :studies, :position, :integer, :null => true
  end
end
