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
        rdf_graph = link_isa(rdf_graph) if self.is_isa?
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

      def rdf_resource
        #FIXME: look at forcing UrlHelper inclusion here, and use that
        uri = Seek::Config.site_base_host+"/#{self.class.name.tableize}/#{self.id}"
        RDF::Resource.new(uri)
      end

      private

      #links investigations to studeies to assays
      def link_isa rdf_graph
        resource = self.rdf_resource

        if is_a? Investigation
          studies.each do |study|
            rdf_graph << [resource,JERMVocab.hasPart,study.rdf_resource]
          end
        end

        if is_a? Study
          assays.each do |assay|
            rdf_graph << [resource,JERMVocab.hasPart,assay.rdf_resource]
          end
          rdf_graph << [resource,JERMVocab.isPartOf,investigation.rdf_resource]
        end

        if is_a? Assay
          rdf_graph << [resource,JERMVocab.isPartOf,study.rdf_resource]
        end
        rdf_graph
      end

      def describe_type rdf_graph
       it_is = JERMVocab.for_type self
       unless it_is.nil?
         resource = self.rdf_resource
         rdf_graph <<  [resource,RDF.type,it_is]
       end
       rdf_graph
      end



      #define non rightfield based rdf statements
      def dublin_core_rdf_statements rdf_graph
        resource = self.rdf_resource
        rdf_graph << [resource,RDF::DC.title,title] if self.respond_to?(:title)
        rdf_graph << [resource,RDF::DC.description,description.nil? ? "" : description] if self.respond_to?(:description)
        rdf_graph
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
