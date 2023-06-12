module Seek
  module Samples
    # Defines the base type used for sample attributes, and makes them available as constants
    # for example Seek::Samples::BaseType.DATE_TIME = 'DateTime'
    module BaseType
      ALL_TYPES = %w(Integer Float String DateTime Date Text Boolean SeekStrain SeekSample SeekSampleMulti CV SeekDataFile CVList LinkedCustomMetadata)

      ALL_TYPES.each do |type|
        BaseType.const_set(type.underscore.upcase, type)
      end

      def self.valid?(value)
        ALL_TYPES.include?(value)
      end
    end
  end
end
