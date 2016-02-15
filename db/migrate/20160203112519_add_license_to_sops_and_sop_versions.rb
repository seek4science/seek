class AddLicenseToSopsAndSopVersions < ActiveRecord::Migration
  def change
    add_column :sops, :license, :string
    add_column :sop_versions, :license, :string
  end
end
