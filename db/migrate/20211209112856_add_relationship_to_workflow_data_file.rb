class AddRelationshipToWorkflowDataFile < ActiveRecord::Migration[5.2]
  def change
    add_column :workflow_data_files, :workflow_data_file_relationship_id, :integer
  end
end
