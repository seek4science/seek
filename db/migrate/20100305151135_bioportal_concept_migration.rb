class BioportalConceptMigration < ActiveRecord::Migration
  def self.up
    create_table :bioportal_concepts do |t|
      t.column :ontology_id, :integer
      t.column :ontology_version_id,:integer
      t.column :concept_uri,:string
      t.column :cached_concept_yaml,:text
      t.column :conceptable_id,:integer
      t.column :conceptable_type,:string
    end        
  end
  
  def self.down
    drop_table :bioportal_concepts
  end
end
