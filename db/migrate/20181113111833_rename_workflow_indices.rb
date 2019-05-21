class RenameWorkflowIndices < ActiveRecord::Migration[4.2]
  def change
    # rename_index "workflow_auth_lookup",
    #              "index_workflow_auth_lookup_on_user_id_and_asset_id_and_can_view",
    #              "index_w_auth_lookup_on_user_id_and_asset_id_and_can_view"
    # rename_index "workflow_auth_lookup",
    #              "index_workflow_auth_lookup_on_user_id_and_can_view",
    #              "index_w_auth_lookup_on_user_id_and_can_view"
  end
end
