class AddMetaConfigToOpenbisEndpoints < ActiveRecord::Migration
  def change
    add_column :openbis_endpoints, :meta_config_json, :text
  end
end
