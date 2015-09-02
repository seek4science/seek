class DropEditProjectAndInstitutionFlags < ActiveRecord::Migration

  def up
    remove_column :people,:can_edit_projects
    remove_column :people,:can_edit_institutions
  end

  def down
    add_column :people, :can_edit_projects, :boolean, :default=>false
    add_column :people, :can_edit_institutions, :boolean, :default=>false
  end

end
