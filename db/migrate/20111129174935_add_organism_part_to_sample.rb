class AddOrganismPartToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :organism_part, :string
  end

  def self.down
    remove_column :samples, :organism_part
  end
end
