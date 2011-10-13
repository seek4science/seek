class Book < ActiveRecord::Base
  acts_as_annotatable :name_field => :title
  
  has_many :chapters
end