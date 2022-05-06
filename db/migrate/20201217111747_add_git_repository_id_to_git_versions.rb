class AddGitRepositoryIdToGitVersions < ActiveRecord::Migration[5.2]
  def change
    add_reference :git_versions, :git_repository
  end
end
