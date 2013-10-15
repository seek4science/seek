# This migration comes from taverna_player (originally 20130704095504)
class AddAttachmentResultsToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    add_attachment :taverna_player_runs, :results
  end
end
