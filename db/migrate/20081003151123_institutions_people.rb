class InstitutionsPeople < ActiveRecord::Migration
  def self.up
    create_table :institutions_people, :id=>false do |t|
      t.integer :institution_id, :null=>false
      t.integer :person_id, :null=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :institutions_people
  end
end
