module Seek
  module BioSchema
    # mock object, to represent a model to support DataCatalogue.
    # Since DataCatalogue maps to the whole system, rather than an individual entity,
    # this allows the attributes required to appear and behave like a normal database record backed entity.
    class DataCatalogMockModel
      include Seek::BioSchema::Support

      def description
        Seek::Config.instance_description
      end

      def title
        Seek::Config.instance_name
      end

      def keywords
        Seek::Config.project_keywords&.split(',')&.collect(&:strip)&.reject(&:blank?)&.join(', ')
      end

      def provider
        {
          '@type' => 'Organization',
          '@id' => Seek::Config.dm_project_link,
          'name' => Seek::Config.dm_project_name,
          'url' => Seek::Config.dm_project_link
        }
      end

      def created_at
        ActivityLog.order(:id).first.try(:created_at)
      end

      def updated_at
        ActivityLog.order(:id).last.try(:updated_at)
      end

      def url
        Seek::Config.site_base_host
      end

      def schema_org_supported?
        true
      end

      def is_a_version?
        false
      end
    end
  end
end
