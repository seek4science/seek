module Seek
  module Templates
    class Reader
      include SysMODB::SpreadsheetExtractor

      attr_reader :template_content_blob

      ColumnDetails = Struct.new(:label, :column)
      Data = Struct.new(:column, :value)

      def initialize(template_content_blob)
        @template_content_blob = template_content_blob
      end

      def column_details sheet_id
        return nil unless compatible?
        cells = template_xml_document.find("//ss:sheet[@index='#{sheet_id}']/ss:rows/ss:row[@index=1]/ss:cell")
        cells.collect do |cell|
          unless (heading = cell.content).blank?
            ColumnDetails.new(heading, cell.attributes['column'].to_i)
          end
        end.compact
      end

      def each_record(sheet_id, columns = nil)
        rows = template_xml_document.find("//ss:sheet[@index='#{sheet_id}']/ss:rows/ss:row")
        rows.each do |row|
          next if (row_index = row.attributes['index'].to_i) <= 1
          data = row.children.collect do |cell|
            column = cell.attributes['column'].to_i
            if !cell.content.strip.blank? && (columns.nil? || columns.include?(column))
              Data.new(column, cell.content)
            end
          end.compact
          next if data.empty?
          yield(row_index, data)
        end
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
          spreadsheet_to_xml(open(content_blob.filepath), memory_allocation = Seek::Config.jvm_memory_allocation)
        end
      end
    end
  end
end
