# To change this template, choose Tools | Templates
# and open the template in the editor.

class BioportalConcept < ActiveRecord::Base
  include BioPortal::RestAPI

  belongs_to :conceptable,:polymorphic=>true

  def concept_details options={}
    options[:maxchildren]||=nil
    options[:light]||=true
    options[:refresh]||=false

    concept = get_concept(self.ontology_version_id,self.concept_uri,options)
    self.cached_concept_yaml = concept.to_yaml
    return concept
  end

end
