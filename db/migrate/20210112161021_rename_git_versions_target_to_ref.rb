class RenameGitVersionsTargetToRef < ActiveRecord::Migration[5.2]
  def change
    rename_column :git_versions, :target, :ref
  end
end
