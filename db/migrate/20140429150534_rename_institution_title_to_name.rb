class RenameInstitutionTitleToName < ActiveRecord::Migration
  def change
    rename_column :institutions, :name, :title
  end

end
