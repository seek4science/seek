class CreateWorkflowDataFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :workflow_data_files do |t|
      t.integer :workflow_id
      t.integer :data_file_id

      t.index [:workflow_id, :data_file_id], name: 'index_data_files_workflows_on_workflow_data_file'
      t.index [:data_file_id, :workflow_id], name: 'index_data_files_workflows_on_data_file_workflow'
    end
  end
end
