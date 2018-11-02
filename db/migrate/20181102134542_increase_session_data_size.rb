class IncreaseSessionDataSize < ActiveRecord::Migration
  def up
    change_column :sessions, :data, :text, limit: 16.megabytes - 1
  end

  def down
    change_column :sessions, :data, :text, limit: 65535
  end
end
