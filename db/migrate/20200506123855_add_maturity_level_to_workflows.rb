class AddMaturityLevelToWorkflows < ActiveRecord::Migration[5.2]
  def change
    add_column :workflows, :maturity_level, :integer
    add_column :workflow_versions, :maturity_level, :integer
  end
end
