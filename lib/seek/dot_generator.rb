require 'libxml'

module Seek
  module DotGenerator

    class Entry
      attr_accessor :attributes
      attr_accessor :entry_identifier

      def initialize entry_identifier = nil, attributes={}
        @attributes = attributes
        @entry_identifier = entry_identifier
      end

      def attributes_string
        "[#{attributes.collect { |field, value| "#{field}=\"#{h(value).gsub(/\r|\n/," ")}\"" }.join(',')}]" unless attributes.blank?
      end

      def to_s
        "#{entry_identifier} #{attributes_string};\n"
      end
    end

    class Edge < Entry
      def initialize first, second, attributes={}
        super "#{first.entry_identifier} -- #{second.entry_identifier}", attributes
      end

      def == other
        to_s == other.to_s
      end
    end

    class NodeEntry < Entry
      def edge other, attributes={}
        Edge.new(other, self, attributes).to_s
      end
    end

    class Node < NodeEntry
      cattr_accessor :current, :deep, :edges
      cattr_accessor :controller
      attr_accessor :item

      def initialize item, attributes = {}
        @item = item
        super entry_identifier, attributes
      end

      def as_dot
        to_s
      end

      def edge *args
        #keep track of which edges already exist, and don't duplicate them
        edge = super(*args)
        unless edges.include? edge
          edges << edge
          edge
        else
          ""
        end
      end

      def item_type
        item.class.name
      end

      def item_id
        item.id.to_s
      end

      def entry_identifier
        item_type + '_' + item_id
      end

      def children
        []
      end

      def child_nodes
        children.collect { |ch| Node.node_for ch }
      end

      def to_s
        child_nodes.each_with_object(super) do |child, string|
          string << "#{child}#{child.edge self}"
        end
      end

      def self.is_node_class_for? item
        #Node is the default wrapper.
        return true
      end

      # node_for will search descendants, to see if any of them can handle the item.
      #subclasses can specify what objects they handle by overriding self.is_node_class_for?(item)
      def self.node_for item
        #descendants each get to decide if they can handle the item first
        potential_nodes = subclasses.collect do |desc|
          desc.node_for item
        end.compact
        node = potential_nodes.first
        warn "Overlapping is_node_class_for? conditions in subclasses of #{self}. Using first match(#{node.class}), but this may not be the intended behaviour" if potential_nodes.size > 1
        return node if node
        return self.new(item) if is_node_class_for?(item)
      end

      def self.subclasses
        @subclasses ||= []
      end

      def self.inherited(klass)
        #add this inheriting class to my list of subclasses
        subclasses << klass

        #add a default ''is_node_class_for?'
        # this will overwrite any inherited 'is_node_class_for?'
        # Most descendants of Node are for wrapping a particular class.
        # AssayNode, is for wrapping Assay with Node logic, for example
        klass.class_eval do
          def self.is_node_class_for? item
            begin
              return true if item.instance_of? self.name.drop_suffix('Node').constantize
            rescue
              return false
            end
          end
        end
      end
    end

    def node_for item
      Node.node_for item
    end

    def to_dot root_item, deep=false, current_item = nil
      current_item||=root_item

      Node.current = current_item
      Node.deep = deep
      Node.controller = self
      Node.edges = []
      dot = "graph ISA_graph {"
      dot << node_for(root_item).as_dot
      dot << "}"
      return dot
    end
  end
end


class String
  def drop_suffix pattern
    gsub Regexp.new("#{pattern}$"), ''
  end

  def drop_prefix pattern
    gsub Regexp.new("^#{pattern}"), ''
  end

  def multiline line_length=3, max_length=81
    #new string will be max_length or less
    new_str = self[0..(max_length - 1)]


    #split into lines of line_length words
    lines = []
    new_str.split.each_slice(line_length) { |line| lines << line }

    #if the last line has less than the line length, concatenate it with the second to last line.
    lines = lines[0..-3] << lines.last(2).flatten(1) if lines.length > 1 and lines.last.length < line_length
    lines.collect! { |line| line.join(' ') }

    #instead of having multiline insert pre-escaped new lines,
    #maybe it should just insert newlines, and we can use another method for escaping
    new_str = lines.join('\\n')
    new_str += ' ...' if self.length > max_length
    new_str.strip
  end
end

#Seek specific dot stuff.
class SeekNode < Seek::DotGenerator::Node
  def edge other, attributes = {}
    #don't draw edges to me if I'm blank
    if to_s.blank? then "" else super end
  end

  #SeekNode should be used as the default node type
  def self.is_node_class_for? item
    true
  end
end


class InvestigationNode < SeekNode
  def children
    item.studies | item.publications
  end
end

class StudyNode < SeekNode
  def children
    item.assays | item.publications
  end
end

class PublicationNode < SeekNode
  def as_dot
    publication = item
    dot = ""
    pub_node = SeekNode.node_for(publication)
    isa = publication.assays | publication.studies | publication.investigations
    if isa.empty?
      dot << pub_node.to_s
    end
    (isa | publication.data_files | publication.models).each do |asset|
      dot << SeekNode.node_for(asset).to_s
    end
    return dot
  end
end

class AssetNode < SeekNode
  def self.is_node_class_for? item
    item.respond_to? :is_asset? and item.is_asset? and not item.instance_of? Publication
  end

  def children
    current.respond_to?(:contributor) && item.respond_to?(:publications) ? item.publications : []
  end

  def as_dot
    unless item.assays.empty?
      item.assays.each_with_object("") do |assay, string|
        string << SeekNode.node_for(assay).to_s
      end
    else
      super
    end
  end
end

class AssayNode < SeekNode
  def include_defaults
    self.attributes = attributes.merge :shape => :folder
    super
  end

  def children
    deep ? item.assets : []
  end
end



