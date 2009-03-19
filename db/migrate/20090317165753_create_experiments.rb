class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.string :title
      t.integer :assay_id

      t.timestamps
    end
  end

  def self.down
    drop_table :experiments
  end
end
