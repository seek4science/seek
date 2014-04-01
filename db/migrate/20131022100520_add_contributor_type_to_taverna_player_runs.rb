class AddContributorTypeToTavernaPlayerRuns < ActiveRecord::Migration
  change_table :taverna_player_runs do |t|
    t.string :contributor_type
  end
end
