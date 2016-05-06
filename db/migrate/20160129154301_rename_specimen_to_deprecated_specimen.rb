class RenameSpecimenToDeprecatedSpecimen < ActiveRecord::Migration
  def change
    rename_table :specimens, :deprecated_specimens

    rename_table :projects_specimens,:deprecated_specimens_projects
    rename_column :deprecated_specimens_projects,:specimen_id, :deprecated_specimen_id

    rename_column :sop_specimens,:specimen_id,:deprecated_specimen_id
    rename_column :deprecated_samples,:specimen_id,:deprecated_specimen_id
    rename_column :genotypes,:specimen_id,:deprecated_specimen_id
    rename_column :phenotypes,:specimen_id,:deprecated_specimen_id
    rename_column :treatments,:specimen_id,:deprecated_specimen_id

    rename_table :specimen_auth_lookup,:deprecated_specimen_auth_lookup

  end

end
