module Seek
  module Rdf
    module RdfGeneration
      include RightField

      def to_rdf
        rdf_graph = to_rdf_graph
        RDF::Writer.for(:rdfxml).buffer(:prefixes=>ns_prefixes) do |writer|
          rdf_graph.each_statement do |statement|
            writer << statement
          end
        end
      end

      def to_rdf_graph
        rdf_graph = handle_rightfield_contents self
        rdf_graph = describe_type(rdf_graph)
        rdf_graph = dublin_core_rdf_statements(rdf_graph)
        rdf_graph
      end

      def handle_rightfield_contents object
        if (object.respond_to?(:contains_extractable_spreadsheet?) && contains_extractable_spreadsheet? && content_blob.is_xls?)
          generate_rightfield_rdf_graph(self)
        else
          RDF::Graph.new
        end
      end

      private

      def describe_type rdf_graph
       it_is = JERMVocab.for_type self
       unless it_is.nil?
         resource = RDF::Resource.new(rdf_resource_uri(self))
         rdf_graph <<  [resource,RDF.type,it_is]
       end
       rdf_graph
      end



      #define non rightfield based rdf statements
      def dublin_core_rdf_statements rdf_graph
        resource = RDF::Resource.new(rdf_resource_uri(self))
        rdf_graph << [resource,RDF::DC.title,title] if self.respond_to?(:title)
        rdf_graph << [resource,RDF::DC.description,description.nil? ? "" : description] if self.respond_to?(:description)
        rdf_graph
      end


      def rdf_resource_uri object
        #FIXME: look at forcing UrlHelper inclusion here, and use that
        Seek::Config.site_base_host+"/#{object.class.name.tableize}/#{object.id}"
      end

      #the hash of namespace prefixes to pass to the RDF::Writer when generating the RDF
      def ns_prefixes
        {
            "jerm"=>JERMVocab.to_uri.to_s,
            "dc"=>RDF::DC.to_uri.to_s,
            "owl"=>RDF::OWL.to_uri.to_s
        }
      end

    end
  end
end
