class RecommendedModelEnvironment < ActiveRecord::Base
  validates_uniqueness_of :title
  validates_presence_of :title  
end
