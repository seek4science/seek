class Topic < ActiveRecord::Base

  has_many :assays
  belongs_to :project
  
end
