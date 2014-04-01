class AddVersionToWorkflowsAndWorkflowVersions < ActiveRecord::Migration
  def change
    change_table :workflows do |t|
      t.integer :version
    end
    change_table :workflow_versions do |t|
      t.integer :version
    end
  end
end
