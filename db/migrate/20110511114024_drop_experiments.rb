class DropExperiments < ActiveRecord::Migration
  def self.up
    drop_table :experiments
  end

  def self.down
    create_table :experiments do |t|
      t.string :title
      t.integer :sample_id
      t.string :description
      t.integer :project_id
      t.integer :institution_id
      t.integer :people_id
      t.datetime :date
      t.string :first_letter
      t.string :comments
      t.integer :policy_id

      t.timestamps
    end
  end
end
