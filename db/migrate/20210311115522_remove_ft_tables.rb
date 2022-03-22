class RemoveFtTables < ActiveRecord::Migration[5.2]
  def change
    drop_table "ft_projects", if_exists: true
    drop_table "ft_versions", if_exists: true
    drop_table "ft_versions_projects", if_exists: true
    drop_table "fts", if_exists: true
    drop_table "fts_projects", if_exists: true
  end
end
