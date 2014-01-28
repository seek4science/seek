class AnnotationsMigrationV4 < ActiveRecord::Migration
  def self.up
    change_column :annotations,:version,:integer,:null=>true
    change_column :text_values,:version,:integer,:null=>true
    change_column :number_values,:version,:integer,:null=>true
  end

  def self.down
    change_column :annotations,:version,:integer,:null=>false
    change_column :text_values,:version,:integer,:null=>false
    change_column :number_values,:version,:integer,:null=>false
  end
end