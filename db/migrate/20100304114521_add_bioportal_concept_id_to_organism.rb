class AddBioportalConceptIdToOrganism < ActiveRecord::Migration
  def self.up
    add_column :organisms, :bioportal_concept_id, :integer
  end

  def self.down
    remove_column(:organism, :bioportal_concept_id)
  end
end
