class AddNewFieldsToSpecimensForDifferentCultureGrowthTypes < ActiveRecord::Migration
  def self.up

    add_column :specimens,:medium,:string
    add_column :specimens,:culture_format,:string
    add_column :specimens,:temperature,:float
    add_column :specimens,:ph,:float
    add_column :specimens,:confluency,:float
    add_column :specimens,:passage,:integer
    add_column :specimens,:viability,:float
    add_column :specimens,:purity,:float
    add_column :specimens,:sex,:boolean
    add_column :specimens,:born,:datetime

  end

  def self.down
    remove_column :specimens,:medium
    remove_column :specimens,:culture_format
    remove_column :specimens,:temperature
    remove_column :specimens,:ph
    remove_column :specimens,:confluency
    remove_column :specimens,:passage
    remove_column :specimens,:viability
    remove_column :specimens,:purity
    remove_column :specimens,:sex
    remove_column :specimens,:born

  end
end
