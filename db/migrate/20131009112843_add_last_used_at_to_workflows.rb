class AddLastUsedAtToWorkflows < ActiveRecord::Migration
  def change
    change_table :workflows do |t|
      t.datetime :last_used_at
    end
  end
end
