# Taken from BioCatalogue codebase 

class CreateRelationships < ActiveRecord::Migration
  def self.up
    create_table :relationships do |t|
      t.string :subject_type, :null => false
      t.integer :subject_id , :null => false
      t.string :predicate   , :null => false
      t.string :object_type , :null => false
      t.integer :object_id  , :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :relationships
  end
end
