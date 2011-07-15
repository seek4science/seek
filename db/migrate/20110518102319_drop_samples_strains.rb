class DropSamplesStrains < ActiveRecord::Migration
  def self.up
    drop_table :samples_strains
  end

  def self.down
    create_table :samples_strains, :id => false do |t|
      t.integer :sample_id
      t.integer :strain_id
    end
  end
end
