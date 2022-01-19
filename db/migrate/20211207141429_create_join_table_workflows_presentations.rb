class CreateJoinTableWorkflowsPresentations < ActiveRecord::Migration[5.2]
  def change
    create_join_table :workflows, :presentations do |t|
      t.index [:workflow_id, :presentation_id], name: 'index_presentations_workflows_on_workflow_pres'
      t.index [:presentation_id, :workflow_id], name: 'index_presentations_workflows_on_pres_workflow'
    end
  end
end
