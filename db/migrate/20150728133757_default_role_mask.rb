class DefaultRoleMask < ActiveRecord::Migration
  def up
    change_column_default :people, :roles_mask, 0
  end

  def down
    change_column_default :people, :roles_mask, nil
  end
end
