class RemoveDeprecatedSamplesRelatedFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :genotypes, :deprecated_specimen_id, :integer
    remove_column :phenotypes, :deprecated_specimen_id, :integer

  end
end
