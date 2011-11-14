class CreateGenotypes < ActiveRecord::Migration
  def self.up
    create_table :genotypes do |t|
      t.integer :gene_id
      t.integer :modification_id
      t.integer :strain_id
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :genotypes
  end
end
