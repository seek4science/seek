class ProjectObservedVariableSet < ActiveRecord::Migration[5.2]
  def change
    create_table "projects_observed_variable_sets", id: false do |t|
      t.integer "project_id"
      t.integer "observed_variable_set_id"
    end
  end
end
