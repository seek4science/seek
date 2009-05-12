require 'acts_as_ontology'

class TechnologyType < ActiveRecord::Base

  acts_as_ontology

  def title
    super.capitalize
  end

end
