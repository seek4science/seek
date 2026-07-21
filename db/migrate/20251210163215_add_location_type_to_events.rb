class AddLocationTypeToEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :location_type, :integer
  end
end
