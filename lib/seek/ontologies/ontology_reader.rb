module Seek
  module Ontologies
    #the base class for reading ontologies and retrieving the class hierarchy - currently only on rdfs format (if OWL you need to convert first, for example using Protege)
    #a subclass is required to define the ontology file, or url, and the base class URI for the hierarchy tree, see #AssayTypeReader
    class OntologyReader

      attr_reader :ontology

      #access the ontology, or loads it if it hasn't been already. This is preferable to loading on initialize, since
      #the results of parsing will be cached.
      def ontology
        if @ontology.nil?
          load_ontology
        end
        @ontology
      end

      #fetches the class hierarchy with the root node defined by the method #default_parent_class_uri in the implementing class
      #returns an #OntologyClass representing the root node, which itself contains the subclasses as #OntologyClass
      #the result is cached usign Rails.cache, according the root uri and the ontology path
      def class_hierarchy
        parent_uri = default_parent_class_uri
        #Rails.cache.fetch("cls-#{parent_uri}-#{ontology_path}") do
          subclasses = subclasses_for(parent_uri)
          build_ontology_class parent_uri,nil,nil,subclasses
        #end
      end

      private

      def subclasses_for uri
        query = RDF::Query.new :types => {
            RDF::RDFS.subClassOf => uri
        }
        query.execute(self.ontology).collect do |solution|
          uri = solution[:types]
          subclasses = subclasses_for(uri)
          build_ontology_class uri,nil,nil,subclasses
        end
      end

      def build_ontology_class uri,label=nil,description=nil,subclasses=[]
        label ||= fetch_label_for(uri)
        description ||= fetch_description_for(uri)
        OntologyClass.new(uri, label, description, subclasses)
      end

      def fetch_label_for uri
        result = ontology.query(:subject=>uri,:predicate=>RDF::RDFS.label).first
        result.nil? ? result : result.object.to_s
      end

      def fetch_description_for uri
        result = ontology.query(:subject=>uri,:predicate=>RDF::DC11.description).first
        result.nil? ? result : result.object.to_s
      end


      def load_ontology
        path = ontology_path
        @ontology = RDF::Graph.load(path, :format => :rdfxml)
      end

      #constucts the path based upon #ontology_file. if ontology_file is not a valid uri, it is turned into a file path
      #relative to config/ontologies/
      def ontology_path
        file = ontology_file
        if valid_uri_schemes.include?(Addressable::URI.parse(file).scheme)
          file
        else
          File.join(Rails.root,"config","ontologies",ontology_file)
        end
      end

      #the schems for a uri that can be used to treat it as a URI, otherwise a filename is assumed
      def valid_uri_schemes
        ["http","https","file"]
      end

    end
  end
end