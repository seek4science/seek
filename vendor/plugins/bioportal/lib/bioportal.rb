module BioPortal
  module Acts
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_bioportal(options = {}, &extension)
        options[:base_url]="http://rest.bioontology.org/bioportal/"

        extend BioPortal::Acts::SingletonMethods
        include BioPortal::Acts::InstanceMethods
        include BioPortal::RestAPI
      end
    end

    module SingletonMethods

    end

    module InstanceMethods

      require 'BioPortalRestfulCore'
      require 'BioPortalResources'

      def concept maxchildren=nil,light=nil
        return get_concept(bioportal_ontology_version_id,bioportal_concept_uri,maxchildren,light)
      end

    end
  end
  

  module RestAPI
    $REST_URL = "http://rest.bioontology.org/bioportal/"
    
    def get_concept ontology_version_id,concept_id,maxchildren=nil,light=nil
      cc=BioPortalResources::Concept.new({:ontology_id=>ontology_version_id,:concept_id=>concept_id},maxchildren,light)
      rest_uri=cc.generate_uri
      return BioPortalRestfulCore.getConcept(bioportal_ontology_version_id,rest_uri)
    end

    def search ontologies,query,page
      BioPortalRestfulCore.getNodeNameContains ontologies,query,page
    end
  end
    
end

ActiveRecord::Base.class_eval do
  include BioPortal::Acts
end