class CreateAssayAssets < ActiveRecord::Migration
  def self.up
    create_table :assay_assets do |t|
      t.integer :assay_id
      t.integer :asset_id
      t.integer :version

      t.timestamps
    end
  end

  def self.down
    drop_table :assay_assets
  end
end
