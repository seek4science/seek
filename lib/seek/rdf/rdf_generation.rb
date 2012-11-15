module Seek
  module Rdf
    module RdfGeneration
      include RightField

      def to_rdf
        if (contains_extractable_spreadsheet? && content_blob.is_xls?)
          rdf = generate_rdf_graph(self)
        else
          rdf = RDF::Graph.new
        end
        rdf = additional_rdf_statements(rdf)
        RDF::Writer.for(:rdfxml).buffer do |writer|
          rdf.each_statement do |statement|
            writer << statement
          end
        end
      end

      #define non rightfield based rdf statements
      def additional_rdf_statements rdf_graph
        resource = RDF::Resource.new(rdf_resource_uri(self))
        rdf_graph << [resource,RDF::DC.title,title]
        rdf_graph << [resource,RDF::DC.description,description.nil? ? "" : description]
        rdf_graph
      end
    end
  end
end
