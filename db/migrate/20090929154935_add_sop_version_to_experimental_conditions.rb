class AddSopVersionToExperimentalConditions < ActiveRecord::Migration
  def self.up
    add_column :experimental_conditions, :sop_version, :integer
  end

  def self.down
    remove_column :experimental_conditions, :sop_version
  end
end
