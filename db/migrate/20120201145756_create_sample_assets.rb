class CreateSampleAssets < ActiveRecord::Migration
  def self.up
    create_table :sample_assets do |t|
      t.integer :sample_id
      t.integer :asset_id
      t.integer :version
      t.string :asset_type

      t.timestamps

    end
  end

  def self.down
    drop_table :sample_assets
  end
end
