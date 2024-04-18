module Seek
  module ISA
    module TagType
      ALL_TYPES = %w(source source_characteristic sample sample_characteristic protocol other_material other_material_characteristic data_file data_file_comment parameter_value)

      SOURCE_TAGS = %w(source source_characteristic)
      SAMPLE_TAGS = %w(sample sample_characteristic protocol parameter_value)
      OTHER_MATERIAL_TAGS = %w(other_material other_material_characteristic protocol parameter_value)
      DATA_FILE_TAGS = %w(data_file data_file_comment protocol parameter_value)

      ALL_TYPES.each do |type|
        TagType.const_set(type.underscore.upcase, type)
      end

      def self.valid?(value)
        ALL_TYPES.include?(value)
      end
    end
  end
end
