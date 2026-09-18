class RemoveApplicationStatusTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :application_status
  end

  def down
    create_table :application_status do |t|
      t.integer :running_jobs

      t.timestamps
    end
  end
end
