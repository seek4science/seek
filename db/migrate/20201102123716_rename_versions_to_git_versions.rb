class RenameVersionsToGitVersions < ActiveRecord::Migration[5.2]
  def change
    rename_table :versions, :git_versions
  end
end
