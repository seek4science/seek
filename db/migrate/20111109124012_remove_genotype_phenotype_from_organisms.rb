class RemoveGenotypePhenotypeFromOrganisms < ActiveRecord::Migration
  def self.up
    remove_column :organisms,:genotype
    remove_column :organisms,:phenotype

  end

  def self.down
    add_column :organisms,:genotype,:string
    add_column :organisms,:phenotype,:string
  end
end
