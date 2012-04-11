class AddPloidyToSpecimens < ActiveRecord::Migration
  def self.up
    add_column :specimens, :ploidy, :string
  end

  def self.down
    remove_column :specimens, :ploidy
  end
end
