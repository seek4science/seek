class CreateTissueAndCellTypes < ActiveRecord::Migration
  def self.up
    create_table :tissue_and_cell_types do |t|
      t.string :title
      t.integer :organism_id

      t.timestamps

    end

  end

  def self.down
    drop_table :tissue_and_cell_types
  end
end
