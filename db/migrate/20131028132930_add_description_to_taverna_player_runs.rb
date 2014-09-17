class AddDescriptionToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    change_table :taverna_player_runs do |t|
      t.text :description
    end
  end
end
