class CreateObservedVariableSets < ActiveRecord::Migration[5.2]
  def change
    create_table :observed_variable_sets do |t|
      t.string :title
      t.string :contributor_id
      t.string :project_ids

      t.timestamps
    end
  end
end
