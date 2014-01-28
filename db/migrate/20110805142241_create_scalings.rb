class CreateScalings < ActiveRecord::Migration
  def self.up
    create_table :scalings do |t|
      t.integer  "scale_id"
      t.integer  "scalable_id"
      t.integer  "person_id"
      t.string   "scalable_type"
      t.timestamps
      end
  end

  def self.down
    drop_table :scalings
  end

end
