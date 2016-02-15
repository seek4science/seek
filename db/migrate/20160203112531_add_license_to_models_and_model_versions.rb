class AddLicenseToModelsAndModelVersions < ActiveRecord::Migration
  def change
    add_column :models, :license, :string
    add_column :model_versions, :license, :string
  end
end
