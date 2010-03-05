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
      end
    end

    module SingletonMethods

    end

    module InstanceMethods

      require 'BioPortalRestfulCore'
      require 'BioPortalResources'

      def concept options={}
        return nil if self.bioportal_concept.nil?
        return self.bioportal_concept.concept_details options        
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
    require 'xml'    

    $REST_URL = "http://rest.bioontology.org/bioportal"
    
    def get_concept ontology_id,concept_id,options={}

      options[:light]=(options[:light] && options[:light]!=0) ? 1 : 0
      
      concept_url="/concepts/%ID%?conceptid=%CONCEPT_ID%&"
      concept_url=concept_url.gsub("%ID%",ontology_id.to_s)
      concept_url=concept_url.gsub("%CONCEPT_ID%",URI.encode(concept_id))
      options.keys.each{|key| concept_url += "#{key.to_s}=#{URI.encode(options[key].to_s)}&"}
      concept_url=concept_url[0..-2]
      full_concept_path=$REST_URL+concept_url
      parser = XML::Parser.io(open(full_concept_path))
      doc = parser.parse
      
      results = BioPortalRestfulCore.errorCheckLibXML(doc)

      unless results.nil?
        return results
      end

      return process_concepts_xml(doc).merge({:ontology_version_id=>ontology_id})
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

    def get_ontology_versions
      uri=$REST_URL+"/ontologies"
      parser = XML::Parser.io(open(uri))
      doc = parser.parse

      ontologies = BioPortalRestfulCore.errorCheck(doc)

      unless ontologies.nil?
        return ontologies
      end

      return parse_ontologies_xml doc
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
      options[:offset]||=0
      uri="/concepts/#{ontology_version_id}/all?"
      options.keys.each{|k|uri+="#{k}=#{URI.encode(options[k].to_s)}&"}
      uri=uri[0..-2]
      uri=$REST_URL + uri      
      parser = XML::Parser.io(open(uri))
      doc = parser.parse

      concepts = BioPortalRestfulCore.errorCheck(doc)
      unless concepts.nil?
        return concepts
      end

      concepts=[]
      doc.find("/*/data/list/classBean").each{ |element|
        concepts << process_concept_bean_xml(element)
      }
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

    private

    def process_concepts_xml doc
      doc.find("/*/data/classBean").each{ |element|
        return process_concept_bean_xml(element)
      }      
    end

    def parse_ontologies_xml doc
      ontologies=[]
      doc.find("/*/data/list/ontologyBean").each{ |element|
        ontologies << parse_ontology_bean_xml(element)
      }
      return ontologies
    end

    def process_concept_bean_xml element
      result = {}
      ["id","label","fullId","type"].each do |x|
        node = element.first.find("#{element.path}/#{x}")
        result[x.to_sym] = node.first.content unless node.first.nil?
      end
      result[:full_id]=result.delete(:fullId) #convert to ruby style

      childcount = element.first.find(element.path + "/relations/entry[string='ChildCount']/int")
      result[:child_count] = childcount.first.content.to_i unless childcount.first.nil?

      # get synonyms
      synonyms = element.first.find(element.path + "/synonyms/string")
      result[:synonyms] = []
      synonyms.each do |synonym|
        result[:synonyms] << synonym.content
      end

      definitions = element.first.find(element.path + "/definitions/string")
      result[:definitions] = []
      definitions.each do |definition|
        result[:definitions] << definition.content
      end

      if (element.path == "/success/data/classBean")
        result[:children]=process_concept_children(element)
        result[:parents]=process_concept_parents(element)
      end

      return result
    end

    def parse_ontology_bean_xml element
      result = {}
      ["id","ontologyId","displayLabel","description","abbreviation","format","versionNumber","contactName","contactEmail","statusId","isFoundry","dateCreated"].each do |x|
        node = element.first.find("#{element.path}/#{x}")
        result[x.to_sym] = node.first.content unless node.first.nil?
      end
      result[:label]=result.delete(:displayLabel)
      result[:ontology_id]=result.delete(:ontologyId)
      result[:version_number]=result.delete(:versionNumber)
      result[:contact_name]=result.delete(:contactName)
      result[:contact_email]=result.delete(:contactEmail)
      result[:status_id]=result.delete(:statusId)
      result[:is_foundry]=result.delete(:isFoundry)
      result[:date_created]=result.delete(:dateCreated)
      return result
    end

    def process_concept_parents element
      search = element.path + "/relations/entry[string='SuperClass']/list/classBean"
      results = element.first.find(search)
      result=[]
      unless results.empty?
        results.each do |child|
          result << process_concept_bean_xml(child)
        end
      end
      return result
    end

    def process_concept_children element
      search = element.path + "/relations/entry[string='SubClass']/list/classBean"
      results = element.first.find(search)
      result=[]
      unless results.empty?
        results.each do |child|
          result << process_concept_bean_xml(child)
        end
      end
      return result
    end
    
  end
    
end

