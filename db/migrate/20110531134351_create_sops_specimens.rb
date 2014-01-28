class CreateSopsSpecimens < ActiveRecord::Migration
  def self.up
    create_table :sop_specimens do |t|
      t.integer :specimen_id
      t.integer :sop_id
      t.integer :sop_version
    end
  end

  def self.down
    drop_table :sop_specimens
  end
end
