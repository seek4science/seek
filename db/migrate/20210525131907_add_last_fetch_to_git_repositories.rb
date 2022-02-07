class AddLastFetchToGitRepositories < ActiveRecord::Migration[5.2]
  def change
    add_column :git_repositories, :last_fetch, :datetime
  end
end
