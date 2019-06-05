class RenameGalaxyExectionStdOutToStepJson < ActiveRecord::Migration[5.2]
  def change
    rename_column :galaxy_execution_queue_items, :std_out, :step_json
  end
end
