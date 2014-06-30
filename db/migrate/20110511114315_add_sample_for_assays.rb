class AddSampleForAssays < ActiveRecord::Migration
  def self.up
    add_column :assays,:sample_id,:integer
  end

  def self.down
    remove_column :assays,:sample_id
  end
end
