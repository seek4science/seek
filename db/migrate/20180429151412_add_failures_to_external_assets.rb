class AddFailuresToExternalAssets < ActiveRecord::Migration
  def change
    add_column :external_assets, :failures, :integer, default: 0
  end
end
