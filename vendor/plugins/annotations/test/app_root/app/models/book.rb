class Book < ActiveRecord::Base
  acts_as_annotatable
  
  has_many :chapters
end