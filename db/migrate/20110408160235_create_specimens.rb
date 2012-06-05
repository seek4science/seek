class CreateSpecimens < ActiveRecord::Migration
  def self.up
    create_table :specimens do |t|
      t.string :donor_number
      t.integer :organism_id
      t.integer :strain_id
      t.integer :age
      t.string :treatment

      t.string :lab_internal_number
      t.integer :person_id
      t.integer :institution_id
      t.string :comments
      t.string :first_letter
      t.integer :policy_id
      t.text :other_creators
      t.integer  :project_id
      t.integer :contributor_id
      t.string :contributor_type
      t.timestamps
    end
  end

  def self.down
    drop_table :specimens
  end
end
