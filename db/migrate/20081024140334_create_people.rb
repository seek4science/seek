class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people, :force => true do |t|
      t.timestamps
    end

  end

  def self.down
    drop_table :people
  end
end
