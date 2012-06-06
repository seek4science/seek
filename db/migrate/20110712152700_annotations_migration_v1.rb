class AnnotationsMigrationV1 < ActiveRecord::Migration
  def self.up
    create_table :annotations, :force => true do |t|
      t.string    :source_type,         :null => false
      t.integer   :source_id,           :null => false
      t.string    :annotatable_type,    :limit => 50, :null => false
      t.integer   :annotatable_id,      :null => false
      t.integer   :attribute_id,        :null => false
      t.text      :value,               :limit => 20000, :null => false
      t.string    :value_type,          :limit => 50, :null => false
      t.integer   :version,             :null => false
      t.integer   :version_creator_id,  :null => true
      t.timestamps
    end
    
    add_index :annotations, [ :source_type, :source_id ]
    add_index :annotations, [ :annotatable_type, :annotatable_id ]
    add_index :annotations, [ :attribute_id ]
    
    create_table :annotation_versions, :force => true do |t|
      t.integer   :annotation_id,       :null => false
      t.integer   :version,             :null => false
      t.integer   :version_creator_id,  :null => true
      t.string    :source_type,         :null => false
      t.integer   :source_id,           :null => false
      t.string    :annotatable_type,    :limit => 50, :null => false
      t.integer   :annotatable_id,      :null => false
      t.integer   :attribute_id,        :null => false
      t.text      :value,               :limit => 20000, :null => false
      t.string    :value_type,          :limit => 50, :null => false
      t.timestamps
    end
    
    add_index :annotation_versions, [ :annotation_id ]
    
    create_table :annotation_attributes, :force => true do |t|
      t.string :name, :null => false
      
      t.timestamps
    end
    
    add_index :annotation_attributes, [ :name ]
    
    create_table :annotation_value_seeds, :force => true do |t|
      t.integer :attribute_id,      :null => false
      t.string  :value,  :null => false
      
      t.timestamps
    end
    
    add_index :annotation_value_seeds, [ :attribute_id ]
  end
  
  def self.down
    drop_table :annotations
    drop_table :annotation_versions
    drop_table :annotation_attributes
    drop_table :annotation_value_seeds
  end
end