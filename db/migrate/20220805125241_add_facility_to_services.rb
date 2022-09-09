class AddFacilityToServices < ActiveRecord::Migration[6.1]
  def up
    unless column_exists? :services, :facility_id
      add_column :services, :facility_id, :integer
    end
  end
  def down
    if column_exists? :services, :facility_id
      remove_column :services, :facility_id, :integer
    end
  end
end
