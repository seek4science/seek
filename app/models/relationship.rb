# Based on Relationship model from BioCatalogue codebase

# *****************************************************************************
# * BioCatalogue: app/models/relationship.rb
# * 
# * Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# * Institute (EMBL-EBI) and the University of Southampton
# * See license.txt for details
# *****************************************************************************


class Relationship < ActiveRecord::Base
  validates_presence_of :subject_id, :object_id
  
  belongs_to :subject , :polymorphic => true
  belongs_to :object, :polymorphic => true
  
  
  # **********************************************************************
  # A set of constants to define the predicates which are currently in use
  
  ATTRIBUTED_TO = "attributed_to"
  CREDITED_FOR = "credited_for"
  
  # **********************************************************************
  
end
