class AddBioportalFieldsToOrganism < ActiveRecord::Migration
  
  def self.up
    add_column :organisms, :bioportal_ontology_id, :integer
    add_column :organisms, :bioportal_ontology_version_id, :integer
    add_column :organisms, :bioportal_concept_uri, :string
  end

  def self.down
    remove_column :organisms, :bioportal_ontology_id
    remove_column :organisms, :bioportal_ontology_version_id
    remove_column :organisms, :bioportal_concept_uri
  end
  
end
