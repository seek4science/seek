class AddTavernaAuthLookupIndexes < ActiveRecord::Migration
  def change
    add_index :workflow_auth_lookup,[:user_id,:can_view]
    add_index :workflow_auth_lookup,[:user_id,:asset_id,:can_view]

    add_index :sweep_auth_lookup,[:user_id,:can_view]
    add_index :sweep_auth_lookup,[:user_id,:asset_id,:can_view]

    add_index :taverna_player_run_auth_lookup,[:user_id,:can_view], :name=>:tav_player_run_user_view_index
    add_index :taverna_player_run_auth_lookup,[:user_id,:asset_id,:can_view],:name=>:tav_player_run_user_asset_view_index
  end

end
