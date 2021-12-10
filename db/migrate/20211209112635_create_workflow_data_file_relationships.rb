class CreateWorkflowDataFileRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :workflow_data_file_relationships do |t|
      t.string :title
      t.string :key

      t.timestamps
    end
  end
end
