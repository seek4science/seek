class AddRootPageToOpenbisEndpoint < ActiveRecord::Migration
  def change
    add_column :openbis_endpoints,:web_endpoint,:string
  end
end
