class AddContributorIdToGitVersions < ActiveRecord::Migration[5.2]
  def change
    add_reference :git_versions, :contributor, index: true
  end
end
