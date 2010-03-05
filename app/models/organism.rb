require 'bioportal'

class Organism < ActiveRecord::Base

  acts_as_bioportal
  
  has_many :assays
  has_many :models
  
  has_and_belongs_to_many :projects

  validates_presence_of :title

end
