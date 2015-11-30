class ResetNilPersonRolesMaskToZero < ActiveRecord::Migration
  def up
    Person.where(roles_mask:nil).update_all(roles_mask:0)
  end

  def down
    #not reversible
  end
end
