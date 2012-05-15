class AddAgeUnitToSpecimens < ActiveRecord::Migration
  def self.up
    add_column :specimens, :age_unit, :string
  end

  def self.down
    remove_column :specimens, :age_unit
  end
end
