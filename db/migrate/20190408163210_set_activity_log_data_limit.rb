class SetActivityLogDataLimit < ActiveRecord::Migration[5.2]
  def up
    change_column :activity_logs, :data,  :text, limit: 16777215
  end

  def down
    change_column :activity_logs, :data,  :text, limit: 4294967295
  end
end
