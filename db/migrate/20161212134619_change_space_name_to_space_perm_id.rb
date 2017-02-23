class ChangeSpaceNameToSpacePermId < ActiveRecord::Migration
  def up
    rename_column :openbis_endpoints,:space_name,:space_perm_id
  end

  def down
    rename_column :openbis_endpoints,:space_perm_id,:space_name
  end
end
