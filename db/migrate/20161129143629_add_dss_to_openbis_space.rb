class AddDssToOpenbisSpace < ActiveRecord::Migration
  def change
    add_column :openbis_spaces,:dss_endpoint, :string
  end
end
