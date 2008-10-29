class Profile < ActiveRecord::Base
  belongs_to :person
  
  validates_presence_of :first_name, :last_name
  
end
