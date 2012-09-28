class RemoveGenotypePhenotypeFromAssayOrganisms < ActiveRecord::Migration
  def self.up
    remove_column :assay_organisms, :genotype_id, :phenotype_id
  end

  def self.down
    add_column :assay_organisms, :genotype_id, :integer
    add_column :assay_organisms, :phenotype_id, :integer
  end
end
