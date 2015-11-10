class AddAdminDefinedRoleProgramme < ActiveRecord::Migration
  def change
    create_table :admin_defined_role_programmes,:force => true do |t|
      t.integer :programme_id
      t.integer :person_id
      t.integer :role_mask
    end
  end

end
