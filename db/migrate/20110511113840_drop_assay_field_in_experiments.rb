class DropAssayFieldInExperiments < ActiveRecord::Migration
  def self.up
    remove_column :experiments, :assay_id
  end

  def self.down
    add_column :experiments, :assay_id, :integer
  end
end
