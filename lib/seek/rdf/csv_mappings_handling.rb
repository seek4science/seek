module Seek
  module Rdf
    module CSVMappingsHandling
      MAPPINGS_FILE = File.join(File.dirname(__FILE__), 'rdf_mappings.csv')

      def generate_from_csv_definitions(rdf_graph)
        # load template

        CSV.open(MAPPINGS_FILE) do |rows|
          rows.select { |row| row.present? && !row.empty? }.each do |row|
            unless row[0].casecmp('class').zero?
              rdf_graph = generate_for_csv_row(rdf_graph, row)
            end
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
        if (klass == '*' || self.class.name == klass) && respond_to?(method)
          rdf_graph = generate_triples_for_csv_row(self, method, property, uri_or_literal, transform, collection_transform, rdf_graph)
        elsif self.class.name == klass # matched the class but the method isnt found
          Rails.logger.warn "Expected to find method #{method} for class #{klass}"
        end
        rdf_graph
      end

      def generate_triples_for_csv_row(subject, method, property, uri_or_literal, transformation, collection_transformation, rdf_graph)
        resource = subject.rdf_resource
        property_uri = eval(property)
        Rails.logger.debug("Generating triples for subject #{rdf_resource}, method #{method}, property #{property_uri}")
        items = subject.send(method)
        # may be an array of items or a single item. Cant use Array(item) or [*item] here cos it screws up times and datetimes
        items = [items] unless items.respond_to?(:each)

        transformation.strip! if transformation
        collection_transformation.strip! if collection_transformation

        # strip out non rdf capable active record models
        items = items.reject do |item|
          item.kind_of?(ActiveRecord::Base) && !Seek::Util.rdf_capable_types.include?(item.class)
        end

        unless collection_transformation.blank?
          Rails.logger.debug("Performing collection transformation: #{collection_transformation}")
          items = eval("items.#{collection_transformation}")
        end
        items.each do |item|
          unless transformation.blank?
            Rails.logger.debug("Performing transformation: #{transformation}")
            item = eval(transformation)
          end
          o = if uri_or_literal.casecmp('u').zero?
                handle_uri_for_item(item)
              else
                handle_literal_for_item(item)
              end

          rdf_graph << [resource, property_uri, o] unless o.nil?
        end
        rdf_graph
      end

      def handle_literal_for_item(item)
        return '' if item.nil?
        if item.is_a?(URI)
          return nil unless item.to_s =~ URI.regexp # rejects invalid URI's
          RDF::Literal.new(item, datatype: RDF::XSD.anyURI)
        else
          RDF::Literal.new(item)
        end
      end

      def handle_uri_for_item(item)
        if item.respond_to?(:rdf_resource)
          item.rdf_resource
        elsif item.class.name.end_with?('::Version') # FIXME: this should be put into explicit_versioning
          uri = item.parent.rdf_resource
          uri.query = "version=#{item.version}"
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
