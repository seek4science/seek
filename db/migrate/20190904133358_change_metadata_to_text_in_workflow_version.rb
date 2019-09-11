class ChangeMetadataToTextInWorkflowVersion < ActiveRecord::Migration[5.2]
  def change
    change_column :workflow_versions, :metadata, :text
  end
end
