class AddVisibilityToVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :data_file_versions, :visibility, :integer
    add_column :document_versions, :visibility, :integer
    add_column :model_versions, :visibility, :integer
    add_column :node_versions, :visibility, :integer
    add_column :presentation_versions, :visibility, :integer
    add_column :sop_versions, :visibility, :integer
    add_column :workflow_versions, :visibility, :integer
  end
end
