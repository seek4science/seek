class AddExtraMetadataToWorkflowClasses < ActiveRecord::Migration[5.2]
  def change
    add_column :workflow_classes, :alternate_name, :string
    add_column :workflow_classes, :identifier, :text
    add_column :workflow_classes, :url, :text
  end
end
