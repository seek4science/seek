module Seek
  class SampleGraphGenerator
    def initialize(sample)
      @sample = sample
    end

    def generate(max_distance = nil)
      hash = gather(@sample, max_distance)
      hash[:edges].uniq!
      hash[:nodes].uniq!

      hash
    end

    private

    def gather(object, max_distance = nil, distance = 0)
      @visited = [] if distance == 0
      @visited << object

      hash = { nodes: [object], edges: [] }
      is_assay = object.is_a?(Assay)

      if max_distance.nil? || (distance < max_distance)
        object.assay_assets.where(asset_type: 'Sample').each do |assay_asset|
          assay_or_sample = is_assay ? assay_asset.asset : assay_asset.assay
          unless @visited.include?(assay_or_sample)
            next_hash = gather(assay_or_sample, max_distance, distance + 1)
            hash[:nodes] += next_hash[:nodes]
            hash[:edges] += next_hash[:edges]
          end

          if assay_asset.incoming_direction?
            edge = [object, assay_or_sample]
          elsif assay_asset.outgoing_direction?
            edge = [assay_or_sample, object]
          else
            edge = nil
          end

          if edge
            edge.reverse! if is_assay
            hash[:edges] << edge
          end
        end
      end

      hash
    end
  end
end
