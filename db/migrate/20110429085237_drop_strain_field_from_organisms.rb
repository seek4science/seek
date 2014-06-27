class DropStrainFieldFromOrganisms < ActiveRecord::Migration
  def self.up
    remove_column :organisms,:strain
  end

  def self.down
    add_column :organisms,:strain, :string
  end
end
