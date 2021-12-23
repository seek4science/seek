class AddTestOptionToOpenBis < ActiveRecord::Migration[5.2]
  def change
    add_column :openbis_endpoints, :is_test, :boolean
  end
end
