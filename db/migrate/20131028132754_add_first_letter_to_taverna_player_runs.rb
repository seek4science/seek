class AddFirstLetterToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    change_table :taverna_player_runs do |t|
      t.string :first_letter, :limit => 1
    end
  end
end
