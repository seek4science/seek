class AddJermSiteRootUri < ActiveRecord::Migration
  def self.up
    add_column :projects, :site_root_uri, :string
  end

  def self.down
    remove_column :projects,:site_root_uri
  end
end
