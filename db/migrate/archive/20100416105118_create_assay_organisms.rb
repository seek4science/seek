class CreateAssayOrganisms < ActiveRecord::Migration
  def self.up
    create_table :assay_organisms do |t|
      t.integer :assay_id
      t.integer :organism_id
      t.integer :culture_growth_type_id
      t.integer :strain_id
      t.integer :phenotype_id
      t.integer :genotype_id

      t.timestamps
    end
  end

  def self.down
    drop_table :assay_organisms
  end
end
