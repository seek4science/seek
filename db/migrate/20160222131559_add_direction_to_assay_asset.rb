class AddDirectionToAssayAsset < ActiveRecord::Migration
  def change
    add_column :assay_assets,:direction,:integer,:default => 0
  end
end
