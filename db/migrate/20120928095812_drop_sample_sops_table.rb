class DropSampleSopsTable < ActiveRecord::Migration
  def self.up
    drop_table :sample_sops
  end

  def self.down
    create_table :sample_sops, :force => true do |t|
      t.integer :sample_id
      t.integer :sop_id
      t.integer :sop_version
    end
  end
end
