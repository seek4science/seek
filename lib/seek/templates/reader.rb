module Seek
  module Templates
    class Reader
      include SysMODB::SpreadsheetExtractor

      attr_reader :template_content_blob

      def initialize(template_content_blob)
        @template_content_blob = template_content_blob
      end

      def compatible?
        template_content_blob && template_content_blob.is_extractable_spreadsheet?
      end

      private

      def template_xml_document
        unless @template_doc
          @template_doc = LibXML::XML::Parser.string(template_xml).parse
          @template_doc.root.namespaces.default_prefix = 'ss'
        end

        @template_doc
      end

      def template_xml
        spreadsheet_content_blob_to_xml(template_content_blob)
      end

      # delegates to #spreadsheet_to_xml passing the content-blob content - and caches the xml based upon
      # the content_blob cache_key
      def spreadsheet_content_blob_to_xml(content_blob)
        Rails.cache.fetch("blob_ss_xml-#{content_blob.cache_key}") do
          spreadsheet_to_xml(open(content_blob.filepath))
        end
      end
    end
  end
end
