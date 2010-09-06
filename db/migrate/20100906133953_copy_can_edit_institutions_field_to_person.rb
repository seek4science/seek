#In case Asset is gone
class User < ActiveRecord::Base  
  belongs_to :person
end

class CopyCanEditInstitutionsFieldToPerson < ActiveRecord::Migration
  def self.up
    add_column(:people, :can_edit_institutions, :boolean, :default=>false)
    User.all.each do |user|      
      if (user.respond_to?("can_edit_institutions") && user.can_edit_institutions?)        
        if (!user.person.nil?)          
          person_id=user.person.id
          execute("UPDATE people SET can_edit_institutions=true where id=#{person_id}")          
        end
      end
    end
  end

  def self.down
    remove_column :people,:can_edit_institutions
  end
end
