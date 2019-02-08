class AddErrMsgToExternalAssets < ActiveRecord::Migration
  def change
    add_column :external_assets, :err_msg, :string
  end
end
