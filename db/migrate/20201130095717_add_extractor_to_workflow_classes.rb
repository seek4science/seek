class AddExtractorToWorkflowClasses < ActiveRecord::Migration[5.2]
  def change
    add_column :workflow_classes, :extractor, :string
  end
end
