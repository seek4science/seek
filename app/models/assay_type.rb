require 'acts_as_ontology'

class AssayType < ActiveRecord::Base

  has_many :assays
  
  acts_as_ontology

end
  

