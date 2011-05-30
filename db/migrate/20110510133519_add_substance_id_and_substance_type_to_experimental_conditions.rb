class AddSubstanceIdAndSubstanceTypeToExperimentalConditions < ActiveRecord::Migration
  def self.up
    add_column :experimental_conditions,:substance_id, :integer
    add_column :experimental_conditions,:substance_type, :string
  end

  def self.down
    remove_column :experimental_conditions,:substance_id
    remove_column :experimental_conditions,:substance_type
  end
end
