class CreateMeasuredItems < ActiveRecord::Migration
  def self.up
    create_table :measured_items do |t|
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :measured_items
  end
end
