module Seek
  module Rdf
    module BioSchemaResourceWrappers
      class Person
        attr_reader :resource

        delegate :title, :description, :first_name, :last_name, :id, :rdf_resource, to: :resource
        def initialize(resource)
          @resource = resource
        end

        def context
          'http://schema.org'
        end

        def image
          if resource.avatar
            "#{Seek::Config.site_base_host}/#{resource.class.table_name}/#{resource.id}/avatars/#{resource.avatar.id}&size=250"
          end
        end

      end
    end
  end
end
