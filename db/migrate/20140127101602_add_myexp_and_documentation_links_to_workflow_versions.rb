class AddMyexpAndDocumentationLinksToWorkflowVersions < ActiveRecord::Migration
  def change
    add_column :workflow_versions, :myexperiment_link, :string
    add_column :workflow_versions, :documentation_link, :string
  end
end
