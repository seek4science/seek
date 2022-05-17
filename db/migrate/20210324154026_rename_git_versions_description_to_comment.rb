class RenameGitVersionsDescriptionToComment < ActiveRecord::Migration[5.2]
  def change
    rename_column :git_versions, :description, :comment
  end
end
