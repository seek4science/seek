class AddContributorProjectInstitutionToSamples < ActiveRecord::Migration
  def self.up
    add_column :samples, :contributor_id,:integer
    add_column :samples,:contributor_type,:string
    add_column :samples,:project_id, :integer
    add_column :samples, :institution_id,:integer
  end

  def self.down
    remove_column :samples, :contributor_id
    remove_column :samples,:contributor_type
    remove_column :samples,:project_id
    remove_column :samples, :institution_id
  end
end
