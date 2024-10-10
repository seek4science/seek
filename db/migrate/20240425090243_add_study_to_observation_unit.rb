class AddStudyToObservationUnit < ActiveRecord::Migration[6.1]
  def change
    add_column :observation_units, :study_id, :bigint
  end
end
