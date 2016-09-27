module Seek
  module Templates
    class SamplesReader < Reader
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
          next if (row_index = row.attributes['index'].to_i) <= 1
          data = row.children.collect do |cell|
            column = cell.attributes['column'].to_i
            if columns.nil? || columns.include?(column)
              Data.new(column, cell.content)
            end
          end.compact
          yield(row_index, data)
        end
      end

      # whether the content blob passed matches the template held by this reader
      def matches?(blob)
        other_handler = Seek::Templates::SamplesReader.new(blob)
        compatible? && other_handler.compatible? && (column_details == other_handler.column_details)
      end

      def build_samples_from_datafile(sample_type,datafile_content_blob)
        samples = []
        columns = sample_type.sample_attributes.collect(&:template_column_index)

        handler = Seek::Templates::SamplesReader.new(datafile_content_blob)
        handler.each_record(columns) do |_row, data|
          samples << build_sample_from_template_data(sample_type,data)
        end
        samples
      end

      private

      def build_sample_from_template_data(sample_type,template_data)
        sample = Sample.new(sample_type: sample_type)
        template_data.each do |entry|
          attribute = sample_type.attribute_for_column(entry.column)
          sample.set_attribute(attribute.hash_key, entry.value) if attribute
        end
        sample
      end

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
