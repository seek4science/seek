module Seek
  module BioSchema
    class DataCatalogueMockModel
      include Seek::BioSchema::Generation

      def description
        Seek::Config.project_description
      end

      def title
        Seek::Config.project_name
      end

      def keywords
        if Seek::Config.project_keywords
          Seek::Config.project_keywords.split(',').collect(&:strip).reject(&:blank?).join(', ')
        end
      end

      def provider
        {
          '@type' => 'Organization',
          'name' => Seek::Config.dm_project_name,
          'url' => Seek::Config.dm_project_link
        }
      end

      def date_created
        ActivityLog.order(:id).first.try(:created_at)
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
