class MergeProfilesIntoPeople < ActiveRecord::Migration
    def self.up
        Person.transaction do 
            add_column :people, :first_name, :string
            add_column :people, :last_name, :string
            add_column :people, :email, :string
            add_column :people, :phone, :string
            add_column :people, :skype_name, :string
            add_column :people, :web_page, :string
    
            execute "update people, profiles set people.first_name=profiles.first_name, people.last_name=profiles.last_name,people.email=profiles.email, people.phone=profiles.phone, people.skype_name=profiles.skype_name, people.web_page=profiles.web_page where people.id=profiles.person_id"
    
            execute "update expertises_profiles,profiles set 
      expertises_profiles.profile_id=profiles.person_id 
      where expertises_profiles.profile_id=profiles.id"
    
            rename_table(:expertises_profiles, :expertises_people)
            rename_column(:expertises_people, :profile_id, :person_id)
    
            drop_table :profiles
    
        end
   
    end

    def self.down
    
        Person.transaction do
    
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
    
            rename_column(:expertises_people, :person_id, :profile_id)
            rename_table(:expertises_people, :expertises_profiles)
    
            People.find(:all) do |person|
                prof = Profile.new(:first_name=>person.first_name, :last_name=>person.last_name, :email=>person.email, :phone=>person.phone, :web_page=>person.web_page, :person_id=>person.id)
                prof.save
                execute "update expertises_profiles set expertises_profiles.profile_id = #{prof.id} where expertises_profiles.profile_id=#{person.id}"
            end
    
            remove_column :people, :first_name, :last_name, :email, :phone, :skype_name, :web_page
        end
    end
end
