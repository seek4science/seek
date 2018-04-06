module Seek
  module Templates
    # Base class for handling of extracting and interpreting metadata from within a Rightfield Template
    class RightfieldExtractor
      include RightField

      attr_reader :csv_parser

      delegate :value_for_property_and_index, :values_for_property, to: :csv_parser

      def initialize(source_data_file)
        @csv_parser = RightfieldCSVParser.new(generate_rightfield_csv(source_data_file))
      end

      private

      def project
        id = seek_id_by_type(Project)
        Project.find_by_id(id) if id
      end

      def seek_id_by_type(type)
        uri = seek_id_uris.find { |id| id.include?("/#{type.name.tableize}/") }
        uri.split('/').last if uri
      end

      def seek_id_uris
        values_for_property(:seekID, :literal).select do |uri|
          uri =~ URI::DEFAULT_PARSER.regexp[:ABS_URI]
        end.select do |uri|
          uri_matches_host?(uri) # reject those that don't match the configured host
        end
      end

      def uri_matches_host?(uri)
        URI.parse(uri).host == URI.parse(Seek::Config.site_base_host).host
      end
    end
  end
end
