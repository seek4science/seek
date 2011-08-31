class DropSampleFieldFromAssays < ActiveRecord::Migration
  def self.up
    remove_column :assays,:sample_id
  end

  def self.down
    add_column :assays,:sample_id,:integer
  end
end
