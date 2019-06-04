class CreateGalaxyExecutionQueueItem < ActiveRecord::Migration[5.2]
  def change
    create_table :galaxy_execution_queue_items do |t|
      t.integer :person_id
      t.integer :data_file_id
      t.integer :sample_id
      t.string :workflow_id
      t.string :history_name
      t.string :history_id
      t.integer :status
      t.text :std_out
      t.string :current_status
      t.integer :delayed_job_id
    end
  end
end
