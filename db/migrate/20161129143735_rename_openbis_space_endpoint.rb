class RenameOpenbisSpaceEndpoint < ActiveRecord::Migration

  def up
    rename_column :openbis_spaces,:url,:as_endpoint
  end

  def down
    rename_column :openbis_spaces,:as_endpoint,:url
  end

end
