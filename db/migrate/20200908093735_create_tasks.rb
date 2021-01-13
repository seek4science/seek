class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.references :resource, polymorphic: true
      t.string :key
      t.string :status
      t.integer :attempts, default: 0
      t.timestamps
    end
  end
end
