# This migration comes from taverna_player (originally 20130811152840)
class AddAttachmentLogToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    add_attachment :taverna_player_runs, :log
  end
end
