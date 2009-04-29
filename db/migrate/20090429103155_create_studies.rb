class CreateStudies < ActiveRecord::Migration
  def self.up
    create_table :studies do |t|
      t.string :title
      t.text :description
      t.integer :investigation_id
      t.string :experimentalists
      t.datetime :begin_date
      t.integer :person_responsible_id
      t.integer :organism_id

      t.timestamps
    end
  end

  def self.down
    drop_table :studies
  end
end
