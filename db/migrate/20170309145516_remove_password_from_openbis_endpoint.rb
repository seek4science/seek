class RemovePasswordFromOpenbisEndpoint < ActiveRecord::Migration
  def up
    remove_column :openbis_endpoints, :password
  end

  def down
    add_column :openbis_endpoints, :password, :string
  end
end
