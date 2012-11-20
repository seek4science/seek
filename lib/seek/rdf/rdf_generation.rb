require 'simple-spreadsheet-extractor'
require 'fastercsv'

module Seek
  module Rdf
    module RdfGeneration
      include RightField
      include SysMODB::SpreadsheetExtractor

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
        rdf_graph = generate_from_xls_template rdf_graph
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
        uri = Seek::Config.site_base_host+"/#{self.class.name.tableize}/#{self.id}"
        RDF::Resource.new(uri)
      end

      private

      def generate_from_xls_template rdf_graph
        #load template
        path_to_template=File.join(File.dirname(__FILE__), "core_rdf_template.xls")
        csv = spreadsheet_to_csv open(path_to_template)
        FasterCSV.parse(csv) do |row|
          unless row[0].downcase=="class"
            klass=row[0]
            method=row[1]
            property=row[2]
            uri_or_literal=row[3].downcase
            if (klass=="*" || self.class.name==klass) && self.respond_to?(method)
              rdf_graph = generate_triples(self,method,property,uri_or_literal,rdf_graph)
            end
          end
        end
        rdf_graph
      end

      def generate_triples subject, method, property,uri_or_literal,rdf_graph
        puts("Generating triple for #{subject}, #{method},#{property},#{uri_or_literal}")
        resource = subject.rdf_resource

        items = Array(subject.send(method)) #may be an array of items or a single item
        items.each do |item|
          property_uri = eval(property)
          o = uri_or_literal.start_with?("l") ? item : item.rdf_resource
          rdf_graph << [resource,property_uri,o]
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
