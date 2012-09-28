class AddIsDummyToStrain < ActiveRecord::Migration
  def self.up
    add_column :strains,:is_dummy,:boolean,:default=>false
  end

  def self.down
    remove_column :strains,:is_dummy
  end
end
