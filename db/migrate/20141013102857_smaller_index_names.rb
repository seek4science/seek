class SmallerIndexNames < ActiveRecord::Migration
  def change
    rename_index :data_file_versions,"index_data_file_versions_on_contributor_id_and_contributor_type","index_data_file_versions_contributor"
    rename_index :investigations_projects,"index_investigations_projects_on_investigation_id_and_project_id","index_investigations_projects_inv_proj_id"
    rename_index :presentations_projects,"index_presentations_projects_on_presentation_id_and_project_id","index_presentations_projects_pres_proj_id"
    rename_index :data_file_auth_lookup,"index_data_file_auth_lookup_on_user_id_and_asset_id_and_can_view","index_data_file_auth_lookup_user_asset_view"
  end


end
