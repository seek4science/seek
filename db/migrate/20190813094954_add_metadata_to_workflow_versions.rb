class AddMetadataToWorkflowVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :workflow_versions, :metadata, :json
  end
end
