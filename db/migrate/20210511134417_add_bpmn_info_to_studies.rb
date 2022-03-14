class AddBpmnInfoToStudies < ActiveRecord::Migration[5.2]
  def change
    add_column :studies, :started_at, :datetime
    add_column :studies, :finished_at, :datetime
    add_column :studies, :status, :integer
    add_column :studies, :assignee_id, :integer
  end
end
