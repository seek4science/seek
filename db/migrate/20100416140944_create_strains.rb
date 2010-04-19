class CreateStrains < ActiveRecord::Migration
  def self.up
    create_table :strains do |t|
      t.string :title
      t.integer :organism_id

      t.timestamps
    end
  end

  def self.down
    drop_table :strains
  end
end
