class ExplicitGitTableIndexNames < ActiveRecord::Migration[6.1]
  # they mave have different names if created with Rails 5 previously and before external release
  def up
    if ActiveRecord::Migration.connection.index_exists? :git_repositories, [:resource_type, :resource_id], name: 'index_git_repositories_on_resource_type_and_resource_id'
      rename_index :git_repositories, 'index_git_repositories_on_resource_type_and_resource_id', 'index_git_repositories_on_resource'
    end
    if ActiveRecord::Migration.connection.index_exists? :git_versions, [:resource_type, :resource_id], name: 'index_git_versions_on_resource_type_and_resource_id'
      rename_index :git_versions, 'index_git_versions_on_resource_type_and_resource_id', 'index_versions_on_resource'
    end
  end

  def down
    rename_index :git_repositories, 'index_git_repositories_on_resource', 'index_git_repositories_on_resource_type_and_resource_id'
    rename_index :git_versions, 'index_versions_on_resource', 'index_git_versions_on_resource_type_and_resource_id'
  end
end
