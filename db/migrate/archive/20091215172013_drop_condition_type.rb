class DropConditionType < ActiveRecord::Migration
  def self.up
    drop_table :condition_types
    remove_column :experimental_conditions, :condition_type_id
  end

  def self.down
    create_table "condition_types", :force => true do |t|
      t.string   "title"
      
      t.timestamps
    end
    add_column :experimental_conditions,:condition_type_id,:integer
  end
end
