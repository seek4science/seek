class AddLabelToAssetLink < ActiveRecord::Migration[5.2]
  def change
    add_column :asset_links,:label, :string
  end
end
