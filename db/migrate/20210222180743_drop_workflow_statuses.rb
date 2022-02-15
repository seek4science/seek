class DropWorkflowStatuses < ActiveRecord::Migration[5.2]
  def change
    drop_table :workflow_statuses do |t|
      t.references :workflow
      t.integer :version
      t.string :status
      t.timestamps
    end
  end
end
