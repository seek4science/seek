class CreateWorkflowStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :workflow_statuses do |t|
      t.references :workflow
      t.integer :version
      t.string :status
      t.timestamps
    end
  end
end
