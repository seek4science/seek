class AddMissingAuthTableIndexes < ActiveRecord::Migration
  def up
    add_index "investigation_auth_lookup", ["user_id", "asset_id", "can_view"],:name=>"index_inv_user_id_asset_id_can_view"
    add_index "presentation_auth_lookup", ["user_id", "asset_id", "can_view"],:name=>"index_presentation_user_id_asset_id_can_view"
    add_index "publication_auth_lookup", ["user_id", "asset_id", "can_view"],:name=>"index_pub_user_id_asset_id_can_view"
    add_index "sample_auth_lookup", ["user_id", "asset_id", "can_view"],:name=>"index_sample_user_id_asset_id_can_view"
    add_index "specimen_auth_lookup", ["user_id", "asset_id", "can_view"],:name=>"index_spec_user_id_asset_id_can_view"
    add_index "strain_auth_lookup", ["user_id", "asset_id", "can_view"],:name=>"index_strain_user_id_asset_id_can_view"
  end

  def down
    remove_index "investigation_auth_lookup", :name=>"index_inv_user_id_asset_id_can_view"
    remove_index "presentation_auth_lookup", :name=>"index_presentation_user_id_asset_id_can_view"
    remove_index "publication_auth_lookup", :name=>"index_pub_user_id_asset_id_can_view"
    remove_index "sample_auth_lookup", :name=>"index_sample_user_id_asset_id_can_view"
    remove_index "specimen_auth_lookup", :name=>"index_spec_user_id_asset_id_can_view"
    remove_index "strain_auth_lookup", :name=>"index_strain_user_id_asset_id_can_view"
  end
end
