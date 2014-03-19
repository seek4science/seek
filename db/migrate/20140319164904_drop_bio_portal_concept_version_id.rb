class DropBioPortalConceptVersionId < ActiveRecord::Migration
  def change
    remove_column :bioportal_concepts,:ontology_version_id
  end

end
