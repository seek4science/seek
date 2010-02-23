class DropFactorTypes < ActiveRecord::Migration
  def self.up

    drop_table :factor_types
    
    remove_column :studied_factors,:factor_type_id

  end

  def self.down
    
    create_table "factor_types", :force => true do |t|
      t.string   "title"

      t.timestamps
    end

    add_column :studied_factors,:factor_type_id,:integer
  end
end
