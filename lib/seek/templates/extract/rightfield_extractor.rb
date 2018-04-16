module Seek
  module Templates
    module Extract
      # Base class for handling of extracting and interpreting metadata from within a Rightfield Template
      class RightfieldExtractor
        include RightField

        attr_reader :current_user

        delegate :value_for_property_and_index, :values_for_property, to: :@parser

        def initialize(source_data_file, current_user = User.current_user)
          @current_user = current_user
          @parser = RightfieldCSVParser.new(generate_rightfield_csv(source_data_file))
          @warnings = Warnings.new

        end

        private

        def project
          project = item_for_type(Project)
          if project && !current_user.person.member_of?(project)
            add_warning("You are not a member of the #{I18n.t('project')} specified",project.title)
            project = nil
          end
          project
        end

        def item_for_type(type, permission_to_check='view')
          uri = seek_uri_by_type(type)
          item = nil
          if uri && verify_uri_for_host(uri, type)
            id = uri.split('/').last
            item = type.find_by_id(id)
            unless item
              type_name = I18n.t(type.name.underscore)
              add_warning("No item could found in the database for the #{type_name}",uri)
            end
          end
          if item && item.authorization_supported? && !item.authorized_for_action(permission_to_check)
            add_warning(
                "You do no have permission to #{permission_to_check.to_s} the #{I18n.t(type.name.underscore)}",
                uri)
            item = nil
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
            add_warning("The SEEK ID for the #{I18n.t(type.name.underscore)} does not match this instance of SEEK",uri)
          end
          valid
        end

        def add_warning(text, value)
          @warnings.add(nil, text, value)
        end

      end
    end
  end
end
