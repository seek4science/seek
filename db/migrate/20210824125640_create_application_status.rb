class CreateApplicationStatus < ActiveRecord::Migration[5.2]
  def change
    create_table :application_status do |t|
      t.integer :running_jobs
      t.boolean :soffice_running

      t.timestamps
    end
  end
end
