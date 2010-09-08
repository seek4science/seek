#In case Asset is gone
class User < ActiveRecord::Base  
  belongs_to :person
end

class CopyIsAdminFieldToPerson < ActiveRecord::Migration
  def self.up
    add_column(:people, :is_admin, :boolean, :default=>false)
    User.all.each do |user|      
      if (user.respond_to?("is_admin") && user.is_admin?)        
        if (!user.person.nil?)          
          person_id=user.person.id
          execute("UPDATE people SET is_admin=true where id=#{person_id}")          
        end
      end
    end
  end

  def self.down
    remove_column :people,:is_admin
  end
end
