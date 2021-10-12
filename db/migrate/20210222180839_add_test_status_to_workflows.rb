class AddTestStatusToWorkflows < ActiveRecord::Migration[5.2]
  def change
    add_column :workflows, :test_status, :integer
    add_column :workflow_versions, :test_status, :integer
  end
end
