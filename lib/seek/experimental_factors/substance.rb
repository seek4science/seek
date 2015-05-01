module Seek
  module ExperimentalFactors
    class Substance
      # required to appear like a text tag
      alias_attribute :text, :name

      attr_reader :id

      attr_writer :id

      attr_reader :name

      attr_writer :name
    end
    end
end
