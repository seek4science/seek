class AddIndexesToProjectsJoinTables < ActiveRecord::Migration[7.2]
  def change
    add_index :projects_observed_variable_sets, [:observed_variable_set_id, :project_id],
              name: 'index_projects_ovs_on_ovs_id_and_project_id'
    add_index :projects_observed_variable_sets, :project_id

    add_index :projects_publication_versions, [:version_id, :project_id],
              name: 'index_projects_pub_versions_on_version_id_and_project_id'
    add_index :projects_publication_versions, :project_id

    add_index :projects_samples, [:sample_id, :project_id]
    add_index :projects_samples, :project_id

    add_index :projects_sop_versions, [:version_id, :project_id]
    add_index :projects_sop_versions, :project_id

    add_index :projects_sops, [:sop_id, :project_id]
    add_index :projects_sops, :project_id

    add_index :projects_strains, [:strain_id, :project_id]
    add_index :projects_strains, :project_id

    add_index :projects_workflow_versions, [:version_id, :project_id]
    add_index :projects_workflow_versions, :project_id

    add_index :projects_workflows, [:workflow_id, :project_id]
    add_index :projects_workflows, :project_id
  end
end
