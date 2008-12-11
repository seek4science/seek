# THIS IS A DESCTRUCTIVE MIGRATION. PROFILES AND EXPERTISE ARE NOT PRESERVED
class MergeProfilesIntoPeople < ActiveRecord::Migration
  def self.up
         
    add_column :people, :first_name, :string
    add_column :people, :last_name, :string
    add_column :people, :email, :string
    add_column :people, :phone, :string
    add_column :people, :skype_name, :string
    add_column :people, :web_page, :string
    
           
    rename_table(:expertises_profiles, :expertises_people)
    rename_column(:expertises_people, :profile_id, :person_id)
            
    #all expertise is destroyed - there isn't currenlty any REAL data to be concerned about at this moment in time
    Expertise.delete_all if (Object.const_defined?("Expertise"))
    
    drop_table :profiles
   
  end

  def self.down
    
    create_table :profiles, :force => true do |t|
      t.string   :first_name
      t.string   :last_name
      t.string   :email
      t.string   :phone
      t.string   :skype_name
      t.string   :web_page
      t.integer  :person_id,  :limit => 11
    
      t.timestamps
    end
    
    Expertise.delete_all if (Object.const_defined?("Expertise"))
    rename_column(:expertises_people, :person_id, :profile_id)
    rename_table(:expertises_people, :expertises_profiles)
    
    
    remove_column :people, :first_name, :last_name, :email, :phone, :skype_name, :web_page
       
  end
end
