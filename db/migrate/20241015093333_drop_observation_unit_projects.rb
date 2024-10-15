class DropObservationUnitProjects < ActiveRecord::Migration[6.1]
  def change
    drop_table :observation_units_projects, id: false do |t|
      t.integer :project_id
      t.integer :observation_unit_id
      t.index ["observation_unit_id", "project_id"], name: "index_projects_obs_units_on_obs_unit_id_and_project_id"
      t.index ["project_id"], name: "index_projects_obs_units_on_project_id"
    end
  end
end
