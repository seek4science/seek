class AddSdToStudiedFactor < ActiveRecord::Migration

  def self.up
    add_column :studied_factors, :standard_deviation, :float
  end

  def self.down
    remove_column :studied_factors,:standard_deviation
  end

end
