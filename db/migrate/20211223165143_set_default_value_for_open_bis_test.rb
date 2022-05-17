class SetDefaultValueForOpenBisTest < ActiveRecord::Migration[5.2]
  def change
    change_column_default :openbis_endpoints, :is_test, from: nil, to: false
  end
end
