class DropSubstanceInExperimentalConditionsTable < ActiveRecord::Migration
  def self.up
    remove_column :experimental_conditions,:substance_type
    remove_column :experimental_conditions,:substance_id
  end

  def self.down
    add_column :experimental_conditions,:substance_type ,:string
    add_column :experimental_conditions,:substance_id ,:integer
  end
end
