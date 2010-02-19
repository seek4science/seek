class CreateOrganisms < ActiveRecord::Migration
  def self.up
    create_table :organisms do |t|
      t.string :title
      t.integer :ncbi_id
      t.string :strain
      t.string :genotype
      t.string :phenotype

      t.timestamps
    end
  end

  def self.down
    drop_table :organisms
  end
end
