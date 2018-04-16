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
          item = nil
          if uri && verify_uri_for_host(uri, type)
            id = uri.split('/').last
            item = type.find_by_id(id)
            if !item
              type_name = I18n.t(type.name.underscore)
              add_warning("No item could found in the database for the #{type_name}",uri)
            end
          end
          item
        end

        def seek_uri_by_type(type)
          seek_id_uris.find { |id| id.include?("/#{type.name.tableize}/") }
        end

        def seek_id_uris
          values_for_property(:seekID, :literal).select do |uri|
            valid = uri =~ URI::DEFAULT_PARSER.regexp[:ABS_URI]
            unless valid || uri.blank?
              add_warning("A SEEK ID was found that is not a valid URI",uri)
            end
            valid
          end
        end

        def verify_uri_for_host(uri, type)
          valid = URI.parse(uri).host == URI.parse(Seek::Config.site_base_host).host
          unless valid
            add_warning("The ID for the #{I18n.t(type.name.underscore)} does not match this instance of SEEK",uri)
          end
          valid
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
