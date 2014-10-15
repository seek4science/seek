class FixBooleanTypesForTavernaRelatedAuthLookUps < ActiveRecord::Migration
  def up
    change_column :workflow_auth_lookup,:can_view,:boolean
    change_column :workflow_auth_lookup,:can_manage,:boolean
    change_column :workflow_auth_lookup,:can_edit,:boolean
    change_column :workflow_auth_lookup,:can_download,:boolean
    change_column :workflow_auth_lookup,:can_delete,:boolean

    change_column :sweep_auth_lookup,:can_view,:boolean
    change_column :sweep_auth_lookup,:can_manage,:boolean
    change_column :sweep_auth_lookup,:can_edit,:boolean
    change_column :sweep_auth_lookup,:can_download,:boolean
    change_column :sweep_auth_lookup,:can_delete,:boolean

    change_column :taverna_player_run_auth_lookup,:can_view,:boolean
    change_column :taverna_player_run_auth_lookup,:can_manage,:boolean
    change_column :taverna_player_run_auth_lookup,:can_edit,:boolean
    change_column :taverna_player_run_auth_lookup,:can_download,:boolean
    change_column :taverna_player_run_auth_lookup,:can_delete,:boolean
  end

  def down
    change_column :workflow_auth_lookup,:can_view,:integer
    change_column :workflow_auth_lookup,:can_manage,:integer
    change_column :workflow_auth_lookup,:can_edit,:integer
    change_column :workflow_auth_lookup,:can_download,:integer
    change_column :workflow_auth_lookup,:can_delete,:integer

    change_column :sweep_auth_lookup,:can_view,:integer
    change_column :sweep_auth_lookup,:can_manage,:integer
    change_column :sweep_auth_lookup,:can_edit,:integer
    change_column :sweep_auth_lookup,:can_download,:integer
    change_column :sweep_auth_lookup,:can_delete,:integer

    change_column :taverna_player_run_auth_lookup,:can_view,:integer
    change_column :taverna_player_run_auth_lookup,:can_manage,:integer
    change_column :taverna_player_run_auth_lookup,:can_edit,:integer
    change_column :taverna_player_run_auth_lookup,:can_download,:integer
    change_column :taverna_player_run_auth_lookup,:can_delete,:integer
  end
end
