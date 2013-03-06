class AddDefaultPolicyForStrain < ActiveRecord::Migration
  class Policy < ActiveRecord::Base
  end
  class Strain < ActiveRecord::Base
    belongs_to :policy, :class_name => 'AddDefaultPolicyForStrain::Policy'

  end
  def self.up
     Strain.all.each do |strain|
         #The policy allows public to view the strains.
         strain.create_policy({:access_type => 1, :sharing_scope => 4, :name => 'default for strain migration'})

         #neccessary so that the foreign key in strain.policy_id gets saved
         strain.save
     end
   end

   def self.down
     Strain.all.each do |strain|
       strain.policy_id = nil
       strain.save
     end
   end
end
