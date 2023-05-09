Seek::IsaGraphGenerator # Needed for autoloading some inner classes

module Seek
  class SampleGraphGenerator
    def initialize(sample)
      @sample = sample
    end

    def generate(depth: 2, auth: true)
      @auth = auth
      hash = gather(@sample, depth)
      hash[:edges].uniq!
      hash[:nodes].uniq!

      hash
    end

    private

    def gather(object, max_distance = nil, distance = 0)
      @visited = Set.new if distance == 0
      @visited << object

      node = Seek::IsaGraphNode.new(object)
      node.can_view = object.can_view? if @auth

      hash = { nodes: [node], edges: [] }

      if max_distance.nil? || (distance < max_distance)
        [
          [object.linked_samples, false],
          [object.linking_samples, true]
        ].each do |samples, reverse|
          samples.each do |sample|
            unless @visited.include?(sample)
              next_hash = gather(sample, max_distance, distance + 1)
              hash[:nodes] += next_hash[:nodes]
              hash[:edges] += next_hash[:edges]
            end
            edge = [sample, object]
            edge.reverse! if reverse
            hash[:edges] << edge
          end
        end
      end

      hash
    end
  end
end
