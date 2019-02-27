module Seek
  module BioSchema
    module ResourceWrappers
      class ResourceWrapper
        attr_reader :resource

        def initialize(resource)
          @resource = resource
        end

        def context
          'http://schema.org'
        end

        def schema_type
          @resource.class.name
        end

        def image
          return unless resource.avatar
          "#{Seek::Config.site_base_host}/#{resource.class.table_name}/#{resource.id}/avatars/#{resource.avatar.id}?size=250"
        end

        def identifier
          rdf_resource
        end

        private

        def respond_to_missing?(name, include_private = false)
          resource.respond_to?(name, include_private)
        end

        def method_missing(method, *args, &block)
          if resource.respond_to?(method)
            resource.send(method, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
