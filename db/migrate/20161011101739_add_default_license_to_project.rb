class AddDefaultLicenseToProject < ActiveRecord::Migration

  def change
    add_column :projects,:default_license,:string
  end

end
