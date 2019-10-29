class AddDefaultsToDataFileAuthLookup < ActiveRecord::Migration[5.2]
  def change
    change_column_default :data_file_auth_lookup, :can_view, from: nil, to: false
    change_column_default :data_file_auth_lookup, :can_manage, from: nil, to: false
    change_column_default :data_file_auth_lookup, :can_edit, from: nil, to: false
    change_column_default :data_file_auth_lookup, :can_download, from: nil, to: false
  end
end
