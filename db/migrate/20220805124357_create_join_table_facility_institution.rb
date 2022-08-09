class CreateJoinTableFacilityInstitution < ActiveRecord::Migration[6.1]
  def change
    create_join_table :facilities, :institutions do |t|
      # t.index [:facility_id, :institution_id]
      # t.index [:institution_id, :facility_id]
    end
  end
end
