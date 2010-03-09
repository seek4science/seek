class Organism < ActiveRecord::Base

  linked_to_bioportal :email=>"stuart.owen@manchester.ac.uk"
  
  has_many :assays
  has_many :models
  
  has_and_belongs_to_many :projects

  validates_presence_of :title

end
