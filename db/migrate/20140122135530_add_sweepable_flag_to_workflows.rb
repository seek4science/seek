class AddSweepableFlagToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :sweepable, :boolean
  end
end
