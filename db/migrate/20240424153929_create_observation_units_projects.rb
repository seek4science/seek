class CreateObservationUnitsProjects < ActiveRecord::Migration[6.1]
  def change
    create_table :observation_units_projects, id: false do |t|
      t.integer :project_id
      t.integer :observation_unit_id
    end

    add_index :observation_units_projects, [:observation_unit_id, :project_id], name: :index_projects_obs_units_on_obs_unit_id_and_project_id
    add_index :observation_units_projects, [:project_id], name: :index_projects_obs_units_on_project_id
  end
end
