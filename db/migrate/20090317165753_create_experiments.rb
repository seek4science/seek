class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.string :title
      t.string :description      
      t.integer :experiment_type_id
      t.integer :topic_id

      t.string :experimentalist
      t.datetime :begin_date
      
      t.integer :person_responsible_id
      t.integer :organism_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :experiments
  end
end
