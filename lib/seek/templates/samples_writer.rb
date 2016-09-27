require 'seek/sample_templates'

module Seek
  module Templates
    class SamplesWriter
      attr_reader :sample_type, :tmp_file

      delegate :sample_attributes, :create_content_blob, to: :sample_type

      def initialize(sample_type)
        @sample_type = sample_type
        @tmp_file = "/tmp/#{UUID.generate}.xlxs"
      end

      def generate
        Seek::SampleTemplates.generate(sheet_name, sheet_index, define_columns, tmp_file)
        create_content_blob(template_blob_attributes)
        sample_attributes.each_with_index do |attribute, index|
          attribute.update_attributes(template_column_index: index + 1)
        end
      end

      private

      def define_columns
        sample_attributes.collect(&:template_column_definition)
      end

      def template_blob_attributes
        { tmp_io_object: File.new(tmp_file),
          url: nil,
          external_link: false,
          original_filename: "#{sample_type.title} template.xlsx",
          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          make_local_copy: true,
          asset_version: nil }
      end

      def sheet_name
        'Samples'
      end

      def sheet_index
        1
      end
    end
  end
end
