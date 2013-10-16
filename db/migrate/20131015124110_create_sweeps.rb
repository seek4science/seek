class CreateSweeps < ActiveRecord::Migration
  def change
    create_table :sweeps do |t|
      t.string :name
      t.belongs_to :user
      t.belongs_to :workflow
      t.integer :workflow_version
      t.timestamps
    end
  end
end
