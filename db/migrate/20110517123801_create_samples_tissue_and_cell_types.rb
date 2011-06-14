class CreateSamplesTissueAndCellTypes < ActiveRecord::Migration
  def self.up
    create_table :samples_tissue_and_cell_types ,:id=> false do |t|
        t.integer :sample_id
        t.integer :tissue_and_cell_type_id

    end
  end

  def self.down
    drop_table :samples_tissue_and_cell_types
  end
end
