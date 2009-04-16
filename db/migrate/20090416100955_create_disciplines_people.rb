class CreateDisciplinesPeople < ActiveRecord::Migration
  def self.up
    create_table :disciplines_people, :id=>false do |t|
      t.integer :discipline_id
      t.integer :person_id
    end
  end

  def self.down
    drop_table :disciplines_people
  end
end
