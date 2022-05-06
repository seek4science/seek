class RemoveBpmnColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :assays, :started_at
    remove_column :assays, :finished_at
    remove_column :assays, :status
    remove_column :assays, :assignee_id
    remove_column :investigations, :started_at
    remove_column :investigations, :finished_at
    remove_column :investigations, :status
    remove_column :investigations, :assignee_id
    remove_column :projects, :started_at
    remove_column :projects, :finished_at
    remove_column :projects, :status
    remove_column :projects, :assignee_id
    remove_column :studies, :started_at
    remove_column :studies, :finished_at
    remove_column :studies, :status
    remove_column :studies, :assignee_id
  end
end
