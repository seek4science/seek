class CreateCompounds < ActiveRecord::Migration
  def self.up
    create_table :compounds do |t|
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :compounds
  end
end
