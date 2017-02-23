class RenameOpenbisSpaceToOpenbisEndpoint < ActiveRecord::Migration
  def up
    rename_table :openbis_spaces, :openbis_endpoints
  end

  def down
    rename_table :openbis_endpoints,:openbis_spaces
  end
end
