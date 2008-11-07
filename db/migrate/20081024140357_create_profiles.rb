class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles, :force => true do |t|
      t.string   :first_name
      t.string   :last_name
      t.string   :email
      t.string   :phone
      t.string   :skype_name
      t.string   :web_page
      t.integer  :person_id
    
      t.timestamps
    end

  end

  def self.down
    drop_table :profiles
  end
end
