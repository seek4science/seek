class Investigation < ActiveRecord::Base
  
  belongs_to :project
  has_many :studies
  
end
