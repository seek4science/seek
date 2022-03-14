class AddDoiToGitVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :git_versions, :doi, :string
  end
end
