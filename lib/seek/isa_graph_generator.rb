module Seek
  class IsaGraphGenerator

    def initialize(object)
      @object = object
    end

    def generate(depth: 1, deep: false, include_parents: false)
      hash = { nodes: [], edges: [] }

      depth = deep ? nil : depth

      # Parents and siblings...
      if include_parents
        parents(@object).each do |parent|
          merge_hashes(hash, descendants(parent, depth))
        end

        # All ancestors...
        merge_hashes(hash, ancestors(@object, depth))
      end

      # Self and descendants...
      merge_hashes(hash, descendants(@object, depth))

      hash
    end

    private

    def merge_hashes(hash1, hash2)
      hash1[:nodes] = (hash1[:nodes] + hash2[:nodes]).uniq
      hash1[:edges] = (hash1[:edges] + hash2[:edges]).uniq
    end

    def descendants(object, max_depth = nil, depth = 0)
      traverse(:children, object, max_depth, depth)
    end

    def ancestors(object, max_depth = nil, depth = 0)
      traverse(:parents, object, max_depth, depth)
    end

    def traverse(method, object, max_depth = nil, depth = 0)
      nodes = [object]
      edges = []

      if max_depth.nil? || (depth < max_depth)
        send(method, object).each do |child|
          hash = traverse(method, child, max_depth, depth + 1)
          nodes += hash[:nodes]
          edges += hash[:edges]
          edges << (method == :parents ? [child, object] : [object, child])
        end
      end

      { nodes: nodes, edges: edges }
    end

    def children(object)
      associations = associations(object)
      associations[:children] + associations[:related]
    end

    def parents(object)
      associations(object)[:parents]
    end

    def associations(object)
      case object
        when Project
          {
              children: object.investigations,
              parents: [object.programme].compact
          }
        when Investigation
          {
              children: object.studies,
              parents: object.projects,
              related: object.publications
          }
        when Study
          {
              children: object.assays,
              parents: [object.investigation],
              related: object.publications
          }
        when Assay
          {
              children: object.assets,
              parents: [object.study],
              related: object.publications
          }
        when Publication
          {
              parents: object.assays | object.studies | object.investigations | object.data_files | object.models
          }
        when DataFile, Model, Sop, Sample, Presentation
          {
              parents: object.assays,
              related: object.publications
          }
      end.reverse_merge!(parents: [], children: [], related: [])
    end

  end
end