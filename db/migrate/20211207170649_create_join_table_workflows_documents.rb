class CreateJoinTableWorkflowsDocuments < ActiveRecord::Migration[5.2]
  def change
    create_join_table :workflows, :documents do |t|
      t.index [:workflow_id, :document_id]
      t.index [:document_id, :workflow_id]
    end
  end
end
