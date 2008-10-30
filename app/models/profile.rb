class Profile < ActiveRecord::Base
  belongs_to :person
  
  has_and_belongs_to_many :expertises
  
  validates_presence_of :first_name, :last_name
  
end
