class AddPositionToInvestigations < ActiveRecord::Migration[5.2]
  def change
    add_column :investigations, :position, :integer, :null => true
  end
end
