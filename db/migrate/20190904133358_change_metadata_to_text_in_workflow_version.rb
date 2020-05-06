class ChangeMetadataToTextInWorkflowVersion < ActiveRecord::Migration[5.2]
  def up
    change_column :workflow_versions, :metadata, :text
  end

  def down
    change_column :workflow_versions, :metadata, :json
  end
end
