module Seek
  module ResearchObjects
    class SnapshotParser
      def self.read(filepath)
        new(ROBundle::File.open(filepath))
      end

      def initialize(ro)
        @ro = ro
      end

      def parse
        parse_isa_tree('metadata.json')
      end

      private

      # Build a tree of the ISA + Asset structure by stitching together metadata.json files
      def parse_isa_tree(path)
        hash = JSON.parse(@ro.read(path))
        %w(contents assays studies assets).each do |key|
          if hash[key] && hash[key].any?
            hash[key].map! { |p| parse_isa_tree("#{p}metadata.json") }
          end
        end

        hash
      end
    end
  end
end
