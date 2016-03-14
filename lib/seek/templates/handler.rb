module Seek
  module Templates
    class Handler
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
        template_doc = LibXML::XML::Parser.string(template_xml).parse
        template_doc.root.namespaces.default_prefix = 'ss'
        template_doc
      end

      def template_xml
        spreadsheet_to_xml(open(template_content_blob.filepath))
      end
    end
  end
end
