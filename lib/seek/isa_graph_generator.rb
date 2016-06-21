module Seek
  class IsaGraphGenerator

    def initialize(object, deep = false)
      @object = object
      @deep = deep
    end

    def generate
      hash = { nodes: [], edges: [] }

      # Parents and siblings...
      parents(@object).each do |parent|
        sibling_hash = @deep ? all_descendants(parent) : immediate_descendants(parent)
        merge_hashes(hash, sibling_hash)
      end

      # Self and descendants...
      descendant_hash = @deep ? all_descendants(@object) : immediate_descendants(@object)
      merge_hashes(hash, descendant_hash)

      hash
    end

    private

    def merge_hashes(hash1, hash2)
      hash1[:nodes] = (hash1[:nodes] + hash2[:nodes]).uniq
      hash1[:edges] = (hash1[:edges] + hash2[:edges]).uniq
    end

    def immediate_parents(object)
      hash = { nodes: [], edges: [] }

      parents(object).each do |parent|
        hash[:nodes] << parent
        hash[:edges] << [parent, object]
      end

      hash
    end

    def immediate_descendants(object)
      hash = { nodes: [object], edges: [] }

      children(object).each do |child|
        hash[:nodes] << child
        hash[:edges] << [object, child]
      end

      hash
    end

    def all_descendants(object, parent = nil)
      nodes = [object]
      edges = parent ? [[parent, object]] : []

      children(object).each do |child|
        hash = all_descendants(child, object)
        nodes += hash[:nodes]
        edges += hash[:edges]
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
              parents: [object.programme]
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