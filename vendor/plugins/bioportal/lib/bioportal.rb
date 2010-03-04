module BioPortal
  module Acts
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_bioportal(options = {}, &extension)
        options[:base_url]="http://rest.bioontology.org/bioportal/"

        has_one :bioportal_concept,:as=>:conceptable,:dependent=>:destroy
        before_save :save_changed_concept

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
        return get_concept(self.ontology_version_id,self.concept_uri,maxchildren,light)
      end

      def ontology_id
        return nil if self.bioportal_concept.nil?
        return self.bioportal_concept.ontology_id
      end

      def ontology_version_id
        return nil if self.bioportal_concept.nil?
        return self.bioportal_concept.ontology_version_id
      end

      def concept_uri
        return nil if self.bioportal_concept.nil?
        return self.bioportal_concept.concept_uri
      end

      def ontology_id= value
        check_concept
        self.bioportal_concept.ontology_id=value
      end

      def ontology_version_id= value
        check_concept
        self.bioportal_concept.ontology_version_id=value
      end

      def concept_uri= value
        check_concept
        self.bioportal_concept.concept_uri=value
      end

      private

      def check_concept
        self.bioportal_concept=BioportalConcept.new if self.bioportal_concept.nil?
      end

      def save_changed_concept
        self.bioportal_concept.save! if !self.bioportal_concept.nil? && self.bioportal_concept.changed?
      end

    end
  end
  

  module RestAPI
    require "rexml/document"
    require 'open-uri'
    require 'uri'

    $REST_URL = "http://rest.bioontology.org/bioportal"
    
    def get_concept ontology_id,concept_id,maxchildren=nil,light=nil
      cc=BioPortalResources::Concept.new({:ontology_id=>ontology_id,:concept_id=>concept_id},maxchildren,light)
      rest_uri=cc.generate_uri
      return BioPortalRestfulCore.getConcept(ontology_id,rest_uri)
    end

    def search query,options={}
      options[:pagesize] ||= 10
      options[:pagenum] ||= 0
      
      search_url="/search/%QUERY%?"
      options.keys.each {|key| search_url+="#{key.to_s}=#{URI.encode(options[key].to_s)}&"}
      search_url=search_url[0..-2] #chop of trailing &
      
      search_url=search_url.gsub("%QUERY%",URI.encode(query))
      full_search_path=$REST_URL+search_url
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

    def get_ontologies_versions
      uri=$REST_URL+"/ontologies"
      doc = REXML::Document.new(open(uri))

      ontologies = BioPortalRestfulCore.errorCheck(doc)

      unless ontologies.nil?
        return ontologies
      end

      ontologies = []
      doc.elements.each("*/data/list/ontologyBean"){ |element|
        ontologies << BioPortalRestfulCore.parseOntology(element)
      }

      return ontologies
    end    

    def get_ontology_categories
      uri=$REST_URL + "/categories"
      doc = REXML::Document.new(open(uri))

      categories = BioPortalRestfulCore.errorCheck(doc)

      unless categories.nil?
        return categories
      end

      categories = []
      doc.elements.each("*/data/list/categoryBean"){ |element|
        categories << BioPortalRestfulCore.parseCategory(element)
      }

      return categories
    end

    def get_ontology_groups
      uri = $REST_URL + "/groups"
      doc = REXML::Document.new(open(uri))

      groups = BioPortalRestfulCore.errorCheck(doc)
      unless groups.nil?
        return groups
      end

      groups = []

      doc.elements.each("*/data/list/groupBean"){ |element|
        unless element.nil?
          groups << BioPortalRestfulCore.parseGroup(element)
        end
      }
      

      return groups
    end    

    #options can include
    # - offset - the offet to start from
    # - limit - the maximum number of terms returns
    def get_concepts_for_ontology_version_id ontology_version_id,options={}
      uri="/concepts/#{ontology_version_id}/all?"
      options.keys.each{|k|uri+="#{k}=#{URI.encode(options[k])}&"}
      uri=uri[0..-2]
      uri=$REST_URL + uri
      
      doc = REXML::Document.new(open(uri))

      concepts = BioPortalRestfulCore.errorCheck(doc)
      unless concepts.nil?
        return concepts
      end

      concepts=[]
      #TODO: parse concept list (xml is different to single concept)
      return concepts
      
    end

    #options can include
    # - offset - the offet to start from
    # - limit - the maximum number of terms returns
    def get_concepts_for_virtual_ontology_id virtual_ontology_id,options={}
      uri="/virtual/ontology/#{virtual_ontology_id}/all?"
      options.keys.each{|k|uri+="#{k}=#{URI.encode(options[k])}&"}
      uri=uri[0..-2]
      uri=$REST_URL + uri
      
      doc = REXML::Document.new(open(uri))

      concepts = BioPortalRestfulCore.errorCheck(doc)
      unless concepts.nil?
        return concepts
      end

      concepts=[]
      #TODO: parse concept list (xml is different to single concept)
      return concepts

    end

  end
    
end

