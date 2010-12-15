class AddCredentialsToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :site_credentials, :string
  end

  def self.down
    remove_column :projects, :site_credentials
  end
end
