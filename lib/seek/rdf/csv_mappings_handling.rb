module Seek
  module Rdf
    module CSVMappingsHandling
      MAPPINGS_FILE = File.join(File.dirname(__FILE__), 'rdf_mappings.csv')
      def generate_from_csv_definitions(rdf_graph)
        # load template
        rows = Rails.cache.fetch('rdf_definitions', expires_in: 1.hour) do
          CSV.read(MAPPINGS_FILE)
        end
        rows.each do |row|
          unless row[0].downcase == 'class'
            rdf_graph = generate_for_csv_row(rdf_graph, row)
          end
        end
        rdf_graph
      end

      def generate_for_csv_row(rdf_graph, row)
        klass = row[0].strip
        method = row[1]
        property = row[2]
        uri_or_literal = row[3].downcase
        transform = row[4]
        collection_transform = row[5]
        if (klass == '*' || self.class.name == klass) && self.respond_to?(method)
          rdf_graph = generate_triples_for_csv_row(self, method, property, uri_or_literal, transform, collection_transform, rdf_graph)
        elsif self.class.name == klass # matched the class but the method isnt found
          Rails.logger.warn "Expected to find method #{method} for class #{klass}"
        end
        rdf_graph
      end

      def generate_triples_for_csv_row(subject, method, property, uri_or_literal, transformation, collection_transform, rdf_graph)
        resource = subject.rdf_resource
        items = subject.send(method)
        # may be an array of items or a single item. Cant use Array(item) or [*item] here cos it screws up times and datetimes
        items = [items] unless items.is_a?(Array)

        transformation.strip! if transformation
        collection_transform.strip! if collection_transform
        unless collection_transform.blank?
          items = eval("items.#{collection_transform}")
        end
        items.each do |item|
          property_uri = eval(property)
          item = eval(transformation) unless transformation.blank?
          o = if uri_or_literal.downcase == 'u'
                handle_uri_for_item(item)
              else
                handle_literal_for_item(item)
              end
          rdf_graph << [resource, property_uri, o] unless o.nil?
        end
        rdf_graph
      end

      def handle_literal_for_item(item)
        item.nil? ? '' : item
      end

      def handle_uri_for_item(item)
        if item.respond_to?(:rdf_resource)
          item.rdf_resource
        elsif item.class.name.end_with?('::Version') # FIXME: this should be put into explicit_versioning
          uri = item.parent.rdf_resource
          uri.query = "version=?#{item.version}"
          uri
        else
          uri = RDF::URI.new(item)
          begin
            uri.validate!
          rescue
            nil
          end
        end
      end
    end
  end
end
