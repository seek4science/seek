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
    require "rexml/document"
    require 'open-uri'
    require 'uri'

    $REST_URL = "http://rest.bioontology.org/bioportal/"
    
    def get_concept ontology_version_id,concept_id,maxchildren=nil,light=nil
      cc=BioPortalResources::Concept.new({:ontology_id=>ontology_version_id,:concept_id=>concept_id},maxchildren,light)
      rest_uri=cc.generate_uri
      return BioPortalRestfulCore.getConcept(bioportal_ontology_version_id,rest_uri)
    end

    def search query,options={}
      options[:pagesize] ||= 10
      options[:pagenum] ||= 0
      
      search_url="search/%QUERY%?"
      options.keys.each {|key| search_url+="#{key.to_s}=#{URI.encode(options[key].to_s)}&"}
      search_url=search_url[0..-2] #chop of trailing &
      
      search_url=search_url.gsub("%QUERY%",URI.encode(query))
      full_search_path=$REST_URL+search_url
      puts full_search_path
      doc = REXML::Document.new(open(full_search_path))

      results = BioPortalRestfulCore.errorCheck(doc)

      unless results.nil?
        return results
      end

      results = []
      doc.elements.each("*/data/page/contents"){ |element|
        results = BioPortalRestfulCore.parseSearchResults(element)
      }

      pages = 1
      doc.elements.each("*/data/page"){|element|
        pages = element.elements["numPages"].get_text.value
      }

      return results,pages

    end
  end
    
end

ActiveRecord::Base.class_eval do
  include BioPortal::Acts
end