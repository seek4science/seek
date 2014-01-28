class AddAssayToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments,:assay_id,:integer
  end

  def self.down
    remove_column :experiments,:assay_id
  end
end
