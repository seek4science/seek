class AddUuidToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    change_table :taverna_player_runs do |t|
      t.string :uuid
    end
  end
end
