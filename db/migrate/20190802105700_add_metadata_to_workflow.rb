class AddMetadataToWorkflow < ActiveRecord::Migration[5.2]
  def change
    add_column :workflows, :metadata, :text
  end
end
