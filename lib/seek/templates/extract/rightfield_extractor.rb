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
            add_warning(Warnings::NOT_A_PROJECT_MEMBER, project)
            project = nil
          end
          project
        end

        def item_for_type(type, permission_to_check = 'view')
          uri = seek_uri_by_type(type)
          item = nil
          if uri && verify_uri_for_host(uri, type)
            id = uri.split('/').last
            item = type.find_by_id(id)
            add_warning(Warnings::NOT_IN_DB, uri, type) unless item
          end
          if item && item.authorization_supported? && !item.authorized_for_action(current_user, permission_to_check)
            add_warning(
              Warnings::NO_PERMISSION,
              uri, [permission_to_check, type]
            )
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
              add_warning(Warnings::ID_NOT_A_VALID_URI, uri)
            end
            valid
          end
        end

        def verify_uri_for_host(uri, type)
          valid = URI.parse(uri).host == URI.parse(Seek::Config.site_base_host).host
          add_warning(Warnings::ID_NOT_MATCH_HOST, uri, type) unless valid
          valid
        end

        def add_warning(problem, value, extra_info = nil)
          @warnings.add(problem, value, extra_info)
        end
      end
    end
  end
end
