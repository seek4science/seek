# This migration comes from taverna_player (originally 20140226135723)
class ChangeTavernaPlayerRunsStatusMessageToUseKeys < ActiveRecord::Migration
  def up
    rename_column :taverna_player_runs, :status_message, :status_message_key

    TavernaPlayer::Run.find_each do |run|
      run.status_message_key = run.saved_state
      run.save
    end
  end

  def down
    rename_column :taverna_player_runs, :status_message_key, :status_message

    TavernaPlayer::Run.find_each do |run|
      run.status_message = run.saved_state.capitalize
      run.save
    end
  end
end
