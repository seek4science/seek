class Tag < ActiveRecord::Base
  acts_as_annotation_value :content_field => :name
  
  validates_presence_of :name
  validates_uniqueness_of :name
end