# This migration comes from taverna_player (originally 20131127171823)
class RemoveUnusedPaperclipColumns < ActiveRecord::Migration
  def up
    remove_column :taverna_player_runs, :results_content_type
    remove_column :taverna_player_runs, :results_updated_at

    remove_column :taverna_player_runs, :log_content_type
    remove_column :taverna_player_runs, :log_updated_at
  end

  def down
    add_column :taverna_player_runs, :log_updated_at, :datetime
    add_column :taverna_player_runs, :log_content_type, :string

    add_column :taverna_player_runs, :results_updated_at, :datetime
    add_column :taverna_player_runs, :results_content_type, :string
  end
end
