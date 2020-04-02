class RemoveMetadataFromWorkflows < ActiveRecord::Migration[5.2]
  def change
    remove_column :workflows, :metadata, :json
  end
end
