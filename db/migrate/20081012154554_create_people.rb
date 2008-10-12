class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :fist_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :skype_name
      t.string :web_page

      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
