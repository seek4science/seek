class AddBpmnInfoToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :started_at, :datetime
    add_column :projects, :finished_at, :datetime
    add_column :projects, :status, :integer
    add_column :projects, :assignee_id, :integer
  end
end
