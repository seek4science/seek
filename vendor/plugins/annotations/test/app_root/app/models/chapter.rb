class Chapter < ActiveRecord::Base
  acts_as_annotatable :name_field => :title
  
  belongs_to :book
end