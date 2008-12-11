class RemoveAllExpertise < ActiveRecord::Migration
  def self.up
    drop_table :expertises
    drop_table :expertises_people
  end

  def self.down
    create_table :expertises do |t|
      t.string  :name
      t.timestamp
    end

    create_table :expertises_people, :id => false do |t|
      t.integer  :expertise_id
      t.integer  :person_id
      t.timestamp
    end

  end
end
