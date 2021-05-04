class AddLastSyncAndRefreshTimestampsToOpenbisEndpoints < ActiveRecord::Migration[5.2]
  def change
    add_column :openbis_endpoints, :last_sync, :datetime
    add_column :openbis_endpoints, :last_cache_refresh, :datetime
  end
end
