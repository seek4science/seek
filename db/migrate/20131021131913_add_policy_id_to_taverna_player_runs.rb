class AddPolicyIdToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    change_table :taverna_player_runs do |t|
      t.belongs_to :policy
    end
  end
end
