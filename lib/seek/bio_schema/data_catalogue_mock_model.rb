module Seek
  module BioSchema
    class DataCatalogueMockModel
      include Seek::BioSchema::Generation

      def description
        Seek::Config.application_description
      end

      def title
        Seek::Config.application_name
      end

      def keywords
        Seek::Config.application_keywords
      end

      def provider
        {
          '@type' => 'Organization',
          'name' => Seek::Config.project_name,
          'url' => Seek::Config.project_link
        }
      end

      def date_created
        ActivityLog.first.created_at
      end

      def url
        Seek::Config.site_base_host
      end

      def schema_org_supported?
        true
      end
    end
  end
end
