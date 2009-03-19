class Assay < ActiveRecord::Base

  has_and_belongs_to_many :experiments
  has_and_belongs_to_many :topics
  
end
