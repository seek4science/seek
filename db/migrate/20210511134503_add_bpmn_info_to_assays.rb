class AddBpmnInfoToAssays < ActiveRecord::Migration[5.2]
  def change
    add_column :assays, :started_at, :datetime
    add_column :assays, :finished_at, :datetime
    add_column :assays, :status, :integer
    add_column :assays, :assignee_id, :integer
  end
end
