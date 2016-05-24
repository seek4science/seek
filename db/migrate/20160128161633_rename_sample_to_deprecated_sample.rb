class RenameSampleToDeprecatedSample < ActiveRecord::Migration
  def change
    rename_table :samples, :deprecated_samples

    rename_table :assays_samples, :assays_deprecated_samples
    rename_column :assays_deprecated_samples, :sample_id, :deprecated_sample_id

    rename_table :projects_samples, :deprecated_samples_projects
    rename_column :deprecated_samples_projects, :sample_id, :deprecated_sample_id

    rename_table :sample_auth_lookup,:deprecated_sample_auth_lookup

    rename_table :samples_tissue_and_cell_types, :deprecated_samples_tissue_and_cell_types
    rename_column :deprecated_samples_tissue_and_cell_types, :sample_id, :deprecated_sample_id

    rename_column :treatments,:sample_id, :deprecated_sample_id

    rename_column :sample_assets,:sample_id, :deprecated_sample_id
  end

end
