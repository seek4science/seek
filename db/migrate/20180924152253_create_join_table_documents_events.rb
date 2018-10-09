class CreateJoinTableDocumentsEvents < ActiveRecord::Migration
  def change
    create_join_table :documents, :events do |t|
      t.index [:document_id, :event_id]
      t.index [:event_id, :document_id]
    end
  end
end
