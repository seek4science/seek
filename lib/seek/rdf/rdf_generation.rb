module Seek
  module Rdf
    module RdfGeneration
      include RightField

      def to_rdf
        rdf = handle_rightfield_contents self

        rdf = dublin_core_rdf_statements(rdf)
        RDF::Writer.for(:rdfxml).buffer do |writer|
          rdf.each_statement do |statement|
            writer << statement
          end
        end
      end

      def handle_rightfield_contents object
        if (object.respond_to?(:contains_extractable_spreadsheet?) && contains_extractable_spreadsheet? && content_blob.is_xls?)
          rdf = generate_rightfield_rdf_graph(self)
        else
          rdf = RDF::Graph.new
        end
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

    end
  end
end
