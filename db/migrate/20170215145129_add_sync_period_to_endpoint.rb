class AddSyncPeriodToEndpoint < ActiveRecord::Migration
  def change
    add_column :openbis_endpoints,:refresh_period_mins,:integer,:default => 120
  end
end
