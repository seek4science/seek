module Seek
  module ISA
    module TagType
      ALL_TYPES = %w(source source_characteristic sample sample_characteristic protocol other_material other_material_characteristic data_file data_file_comment parameter_value)

      ALL_TYPES.each do |type|
        TagType.const_set(type.underscore.upcase, type)
      end

      def self.valid?(value)
        ALL_TYPES.include?(value)
      end
    end
  end
end
