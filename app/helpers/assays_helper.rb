require 'acts_as_ontology_view_helper'

module AssaysHelper
  
  include Stu::Acts::Ontology::ActsAsOntologyViewHelper    

  #assays that haven't already been associated with a study
  def assays_available_for_study_association
    Assay.find(:all,:conditions=>['study_id IS NULL'])
  end


end
