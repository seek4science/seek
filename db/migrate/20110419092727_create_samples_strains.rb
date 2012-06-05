class CreateSamplesStrains < ActiveRecord::Migration
  def self.up
    create_table :samples_strains, :id => false do |t|
      t.integer :sample_id
      t.integer :strain_id
    end
  end

  def self.down
    drop_table :samples_strains
  end
end
