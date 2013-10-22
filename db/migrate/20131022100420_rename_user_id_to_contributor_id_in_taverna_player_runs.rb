class RenameUserIdToContributorIdInTavernaPlayerRuns < ActiveRecord::Migration
  def change
    rename_column :taverna_player_runs, :user_id, :contributor_id
  end
end
