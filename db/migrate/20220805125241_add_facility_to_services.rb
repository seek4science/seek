class AddFacilityToServices < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :facility_id, :integer
  end
end
