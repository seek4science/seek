class AddTimestampsToGitRepositories < ActiveRecord::Migration[5.2]
  def change
    add_timestamps(:git_repositories)
  end
end
