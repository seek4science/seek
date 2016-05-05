module Seek
  module Templates
    class SamplesHandler < Handler
      ColumnDetails = Struct.new(:label, :column)
      Data = Struct.new(:column, :value)

      def compatible?
        super && sheet_index
      end

      def column_details
        return nil unless compatible?
        cells = template_xml_document.find("//ss:sheet[@index='#{sheet_index}']/ss:rows/ss:row[@index=1]/ss:cell")
        cells.collect do |cell|
          unless (heading = cell.content).blank?
            ColumnDetails.new(heading, cell.attributes['column'].to_i)
          end
        end.compact
      end

      def each_record(columns = nil)
        rows = template_xml_document.find("//ss:sheet[@index='#{sheet_index}']/ss:rows/ss:row")
        rows.each do |row|
          if (row_index = row.attributes['index'].to_i) > 1
            data = row.children.collect do |cell|
              column = cell.attributes['column'].to_i
              if columns.nil? || columns.include?(column)
                Data.new(column, cell.content)
              end
            end.compact
            yield(row_index, data)
          end
        end
      end

      private

      def sheet_index
        matches = template_xml_document.find('//ss:sheet').select do |sheet|
          sheet.attributes['name'] =~ /.*samples.*/i
        end
        matches.last.attributes['index'].to_i
      rescue
        nil
      end
    end
  end
end
