class AddTimestampsToGitRepositories < ActiveRecord::Migration[5.2]
  def change
    add_timestamps(:git_repositories, null: true)
    Git::Repository.update_all(created_at: Time.now, updated_at: Time.now)
    change_column_null(:git_repositories, :created_at, false)
    change_column_null(:git_repositories, :updated_at, false)
  end
end
