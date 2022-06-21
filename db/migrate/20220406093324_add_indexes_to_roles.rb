class AddIndexesToRoles < ActiveRecord::Migration[6.1]
  def change
    add_index :roles, [:person_id, :role_type_id]
  end
end
