class DropDelayedJobsTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :delayed_jobs if table_exists?(:delayed_jobs)
  end

  def down
    # Cannot recreate the table structure and data, migration is not reversible
    raise ActiveRecord::IrreversibleMigration
  end
end
