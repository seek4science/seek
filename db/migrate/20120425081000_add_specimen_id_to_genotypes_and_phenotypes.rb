class AddSpecimenIdToGenotypesAndPhenotypes < ActiveRecord::Migration
  def self.up
    add_column :genotypes,:specimen_id,:integer
    add_column :phenotypes, :specimen_id,:integer
  end

  def self.down
    remove_column :genotypes,:specimen_id
    remove_column :phenotypes,:specimen_id
  end
end
