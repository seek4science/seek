class AddUserIdToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    change_table :taverna_player_runs do |t|
      t.belongs_to :user
    end
  end
end
