module Seek
  module Templates
    class RightfieldExtractor
      include RightField

      attr_reader :data_file

      def initialize data_file
        @data_file = data_file
      end

      def populate
        rdf = generate_rightfield_rdf_graph(data_file)
      end
    end
  end
end