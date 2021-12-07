class CreateJoinTableWorkflowsPresentations < ActiveRecord::Migration[5.2]
  def change
    create_join_table :workflows, :presentations do |t|
      t.index [:workflow_id, :presentation_id]
      t.index [:presentation_id, :workflow_id]
    end
  end
end
