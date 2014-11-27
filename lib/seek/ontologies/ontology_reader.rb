module Seek
  module Ontologies
    #the base class for reading ontologies and retrieving the class hierarchy - currently only on rdfs format (if OWL you need to convert first, for example using Protege)
    #a subclass is required to define the ontology file, or url, and the base class URI for the hierarchy tree, see #AssayTypeReader
    class OntologyReader

      include Singleton

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
        @class_hierarchy ||= process_ontology_hierarchy
      end

      #resets the loaded ontology, stored hierarchy and classes and clears the cache
      def reset
        clear_cache
        @class_hierarchy=nil
        @ontology=nil
        @known_classes=nil
      end

      def clear_cache
        Rails.cache.delete(cache_key)
      end

      def class_for_uri uri
        class_hierarchy.hash_by_uri[uri]
      end

      def label_exists? label
        all_labels.include?(label && label.downcase)
      end

      def all_labels
        class_hierarchy.hash_by_label.keys
      end

      def fetch_label_for uri
        result = ontology.query(:subject=>uri,:predicate=>RDF::RDFS.label).first
        result.nil? ? result : result.object.to_s
      end

      def fetch_description_for uri
        result = ontology.query(:subject=>uri,:predicate=>RDF::DC11.description).first
        result.nil? ? result : result.object.to_s
      end

      private

      def default_parent_class_uri
        raise NotImplementedError, "Subclasses must implement a default_parent_class_uri method"
      end

      def ontology_file
        raise NotImplementedError, "Subclasses must implement a ontology_file method"
      end

      def ontology_term_type
        nil
      end

      def process_ontology_hierarchy
        parent_uri = default_parent_class_uri
        OntologyClass # so that the class is loaded before it is needed from the cache
        Rails.cache.fetch(cache_key) do
          subclasses = subclasses_for(parent_uri)
          o = build_ontology_class parent_uri,nil,nil,subclasses
          subclasses.each{|s| s.parents << o}
          o
        end
      end

      def cache_key
        key = Digest::MD5.hexdigest("#{default_parent_class_uri}-#{ontology_path}-#{Rails.env}")
        "onto-hierarchy-1-#{key}"
      end

      def subclasses_for uri
        ontology.query(:predicate=>RDF::RDFS.subClassOf,:object=>uri).collect do |solution|
          uri = solution.subject
          subclasses = subclasses_for(uri)
          o = build_ontology_class uri,nil,nil,subclasses
          subclasses.each do |sub|
            sub.parents << o
          end
          o
        end
      end

      def build_ontology_class uri,label=nil,description=nil,subclasses=[]
        @known_classes||={}
        @known_classes[uri] || begin
          label ||= fetch_label_for(uri)
          description ||= fetch_description_for(uri)
          result = OntologyClass.new(uri, label, description, subclasses, [], ontology_term_type)
          @known_classes[uri]=result
          result
        end

      end


      def load_ontology
        path = ontology_path
        @ontology = RDF::Graph.load(path, :format => :rdfxml)
      end

      #constucts the path based upon #ontology_file. if ontology_file is not a valid uri, it is turned into a file path
      #relative to config/ontologies/
      def ontology_path
        file = ontology_file
        if valid_uri_schemes.include?(RDF::URI.parse(file).scheme)
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