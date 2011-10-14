class AnnotationsMigrationV2 < ActiveRecord::Migration
  def self.up
    add_column :annotation_attributes, :identifier, :string, :null => false
  end

  def self.down
    remove_column :annotation_attributes, :identifier  
  end
end