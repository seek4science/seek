class CreateJoinTableWorkflowsDocuments < ActiveRecord::Migration[5.2]
  def change
    create_join_table :workflows, :documents do |t|
      t.index [:workflow_id, :document_id], name: 'index_documents_workflows_on_workflow_doc'
      t.index [:document_id, :workflow_id], name: 'index_documents_workflows_on_doc_workflow'
    end
  end
end
