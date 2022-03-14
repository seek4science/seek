class AddVisibilityToGitVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :git_versions, :visibility, :integer
  end
end
