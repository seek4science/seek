class CreateExperimentalConditionLinks < ActiveRecord::Migration
  def self.up
    create_table :experimental_condition_links do |t|
      t.string :substance_type
      t.integer :substance_id
      t.integer :experimental_condition_id

      t.timestamps
    end
  end

  def self.down
    drop_table :experimental_condition_links
  end
end
