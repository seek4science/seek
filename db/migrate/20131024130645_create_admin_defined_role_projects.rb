class CreateAdminDefinedRoleProjects < ActiveRecord::Migration
  def change
    create_table :admin_defined_role_projects do |t|
      t.integer :project_id
      t.integer :role_mask
      t.integer :person_id
    end
  end
end
