class AddBpmnInfoToInvestigations < ActiveRecord::Migration[5.2]
  def change
    add_column :investigations, :started_at, :datetime
    add_column :investigations, :finished_at, :datetime
    add_column :investigations, :status, :integer
    add_column :investigations, :assignee_id, :integer
  end
end
