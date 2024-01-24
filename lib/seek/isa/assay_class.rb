module Seek
  module ISA
    module AssayClass
      # Creates constants based on the AssayClass key attributes
      # Example: AssayClass key 'EXP' can be represented by Seek::ISA:AssayClass::EXP
      ALL_TYPES = %w[EXP MODEL STREAM]

      ALL_TYPES.each do |type|
        AssayClass.const_set(type.underscore.upcase, type)
      end

      def self.valid?(value)
        ALL_TYPES.include?(value)
      end
    end
  end
end
