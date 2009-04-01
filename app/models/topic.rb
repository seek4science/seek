class Topic < ActiveRecord::Base
  
  belongs_to :project
  has_many :experiments
  
end
