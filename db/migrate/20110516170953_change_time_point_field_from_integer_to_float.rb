class ChangeTimePointFieldFromIntegerToFloat < ActiveRecord::Migration
  def self.up
    change_column :studied_factors, :time_point, :float
  end

  def self.down
    change_column :studied_factors, :time_point, :integer
  end
end
