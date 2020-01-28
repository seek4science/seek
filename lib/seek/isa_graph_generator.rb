# frozen_string_literal: true

module Seek
  class IsaGraphNode
    attr_accessor :object, :child_count, :can_view

    def initialize(object)
      @object = object
      @child_count = 0
    end

    def can_view?
      can_view
    end
  end

  class ObjectAggregation
    include ActionView::Helpers::TextHelper

    attr_reader :object, :type, :count

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      id == other.id
    end

    def hash
      id.hash
    end

    def id
      "#{@object.class.name}-#{@object.id}-#{@type}-#{@count}"
    end

    def title
      pluralize(@count, @type.to_s.humanize.singularize.downcase)
    end

    def avatar_key
      @type.to_s.pluralize
    end

    def initialize(object, type, children)
      @object = object
      @type = type
      @count = children.count
    end
  end

  class IsaGraphGenerator
    def initialize(object)
      @object = object
    end

    # depth: number of levels of child resources to show (0 = none, nil = all)
    # parent_depth: number of levels of parent resources to show (0 = none, nil = all)
    # sibling_depth: number of levels of sibling resources (other children of immediate parent)to show (0 = none, nil = all)
    # include_self: include the root resource in the tree?
    def generate(depth: 1, parent_depth: nil, sibling_depth: nil, include_self: true, auth: true)
      @auth = auth
      hash = { nodes: [], edges: [] }

      if sibling_depth != 0 # Need to include parents to show siblings
        parent_depth = 1 if parent_depth == 0
      end

      # Self and descendants...
      merge_hashes(hash, descendants(@object, depth))

      if parent_depth != 0
        hash = parents_and_siblings(hash, parents(@object), parent_depth, sibling_depth)
      end

      unless include_self
        hash[:nodes] = hash[:nodes].reject { |n| n.object == @object }
      end

      hash
    end

    private

    def parents_and_siblings(hash, parents, parent_depth, sibling_depth, depth = 0)
      if parent_depth.nil? || depth < parent_depth
        parents.each do |parent|
          merge_hashes(hash, descendants(parent, sibling_depth))
          hash = parents_and_siblings(hash, parents(parent), parent_depth, sibling_depth, depth + 1)
        end
      end
      hash
    end

    def merge_hashes(hash1, hash2)
      hash1[:nodes] = (hash1[:nodes] + hash2[:nodes]).uniq(&:object)
      hash1[:edges] = (hash1[:edges] + hash2[:edges]).uniq
    end

    def descendants(object, max_depth = nil, depth = 0)
      traverse(:children, object, max_depth, depth)
    end

    def ancestors(object, max_depth = nil, depth = 0)
      hash = traverse(:parents, object, max_depth, depth)
      # Set child count for the parent nodes
      hash[:nodes].each do |node|
        node.child_count = children(node.object).count
      end

      hash
    end

    def traverse(method, object, max_depth = nil, depth = 0)
      node = Seek::IsaGraphNode.new(object)
      node.can_view = object.can_view? if @auth

      children = send(method, object)
      node.child_count = children.count if method == :children

      nodes = [node]
      edges = []

      if method == :children
        associations(object)[:aggregated_children].each do |type, method|
          associations = resolve_association(object, method)
          next unless associations.any?
          agg = Seek::ObjectAggregation.new(object, type, associations)
          agg_node = Seek::IsaGraphNode.new(agg)
          agg_node.can_view = true
          nodes << agg_node
          edges << [object, agg]
        end
      end

      if max_depth.nil? || depth < max_depth
        children.each do |child|
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
      combined = (associations[:children].map { |a| resolve_association(object, a) }.flatten +
                  associations[:related].map { |a| resolve_association(object, a) }.flatten).uniq
      combined
    end

    def parents(object)
      associations(object)[:parents].map { |a| resolve_association(object, a) }.flatten.uniq
    end

    def resolve_association(object, association)
      if object.respond_to?('related_' + association.to_s)
        associations = object.send('related_' + association.to_s)
      elsif object.respond_to?(association)
        associations = object.send(association)
      else
        return []
      end

      associations = associations.respond_to?(:each) ? associations : [associations]
      associations.compact
    end

    def associations(object)
      case object
      when Programme
        {
          children: [:projects]
        }
      when Project
        {
          children: [:investigations],
          parents: [:programme]
        }
      when Investigation
        {
          children: [:studies],
          related: [:publications]
        }
      when Study
        {
          children: [:positioned_assays],
          parents: [:investigation],
          related: [:publications]
        }
      when Assay
        {
          children: %i[data_files models sops publications documents],
          parents: [:study],
          # related: [:publications],
          aggregated_children: { samples: :samples }
          # data_files: :data_files,
          # models: :models,
          # sops: :sops,
          # documents: :documents,
          # publications: :publications
        }
      when Publication
        {
          parents: %i[assays studies investigations data_files models presentations],
          related: [:events]
        }
      when DataFile, Document, Model, Sop, Sample, Presentation
        {
          parents: [:assays],
          related: %i[publications events],
          aggregated_children: { samples: :extracted_samples }
        }
      when Event
        {
          parents: %i[presentations publications data_files documents]
        }
      else
        {}
      end.reverse_merge!(parents: [], children: [], related: [], aggregated_children: {})
    end
  end
end
