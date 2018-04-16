module Seek
  module Templates
    module Extract
      # Base class for handling of extracting and interpreting metadata from within a Rightfield Template
      class RightfieldExtractor
        include RightField

        delegate :value_for_property_and_index, :values_for_property, to: :@parser

        def initialize(source_data_file, warnings = Warnings.new)
          @parser = RightfieldCSVParser.new(generate_rightfield_csv(source_data_file))
          @warnings = warnings
        end

        private

        def project
          item_for_type(Project)
        end

        def item_for_type(type)
          uri = seek_uri_by_type(type)
          if uri && verify_uri_for_host(uri, type)
            id = uri.split('/').last
            type.find_by_id(id)
          end
        end

        def seek_uri_by_type(type)
          seek_id_uris.find { |id| id.include?("/#{type.name.tableize}/") }
        end

        def seek_id_uris
          values_for_property(:seekID, :literal).select do |uri|
            uri =~ URI::DEFAULT_PARSER.regexp[:ABS_URI]
          end
        end

        def verify_uri_for_host(uri, _type)
          URI.parse(uri).host == URI.parse(Seek::Config.site_base_host).host
        end

        def add_warning(text, value)
          item = target.class.name.underscore
          @warnings.add(item, text, value)
        end

        # the target item, passed into the concrete subclass. This is currently either an Assay or DataFile to be populated
        attr_reader :target
      end
    end
  end
end
