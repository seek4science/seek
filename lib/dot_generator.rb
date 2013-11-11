require 'libxml'

module DotGenerator

  FILL_COLOURS = {'Sop'=>"cadetblue3",
                  'Model'=>"yellow3",
                  'DataFile'=>"burlywood2",
                  'Investigation'=>"#C7E9C0",
                  'Study'=>"#91c98b",
                  'Assay'=>"#64b466",
                  'Publication'=>"#84B5FD",
                  'Presentation' => "cadetblue2",
                  'Sample' => "orange",
                  'Specimen' => "red"}
  FILL_COLOURS.default = "cadetblue"

  def dot_header title
    dot = "graph #{title} {"
    dot << "rankdir = LR;\n"
    dot << "splines = line;\n"
    dot << "node [fontsize=9,fontname=\"Helvetica\"];\n"
    dot << "bgcolor=transparent;\n"
    dot << "ranksep=0.2;\n"
    dot << "edge [arrowsize=0.6];\n"
    return dot
  end

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
    def initialize entry_identifier, attributes={}
      super
      include_defaults
    end

    def highlight
      self.attributes = attributes.merge :color => :blue, :penwidth => 2
    end

    def include_defaults
      defaults = {:width => 2, :shape => :box, :style => :filled, :fillcolor => 'burlywood2'}
      attributes[:target] = '_top' if attributes[:URL] and !attributes[:target]
      [:label, :tooltip].each { |attr| attributes[attr]=entry_identifier unless attributes[attr] }
      attributes[:label] = attributes[:label].multiline
      self.attributes = defaults.merge(attributes)
    end

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

    def tooltip
      item_type.humanize.upcase + ": " + label
    end

    def label
      item_id
    end

    def include_defaults
      self.current = item unless current
      self.attributes = attributes.merge :label => label, :tooltip=>tooltip, :fillcolor =>color, :URL => url
      highlight if item==current
      super
    end

    def color
      FILL_COLOURS[item_type]
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

    def url
      controller.polymorphic_path(item)
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
    dot = dot_header "Investigation"

    Node.current = current_item
    Node.deep = deep
    Node.controller = self
    Node.edges = []

    dot += node_for(root_item).as_dot
    dot << "}"
    return dot
  end

  def to_svg root_item, deep=false, current_item=nil
    current_item||=root_item
    tmpfile = Tempfile.new("#{root_item.class.name}_dot")
    file = File.new(tmpfile.path, 'w')
    file.puts to_dot(root_item, deep, current_item)
    file.close

    post_process_svg(`dot -Tsvg #{tmpfile.path}`)
  end

  def to_svg_for_publishing root_item, deep=false, current_item=nil, selected_items=[]
    @selected_items = selected_items
    tmpfile = Tempfile.new("#{root_item.class.name}_dot")
    file = File.new(tmpfile.path, 'w')
    file.puts to_dot(root_item, deep, current_item)
    file.close

    post_process_svg_for_publishing(`dot -Tsvg #{tmpfile.path}`)
  end

  def to_png root_item, deep=false, current_item=nil
    tmpfile = Tempfile.new("#{root_item.class.name}_dot")
    file = File.new(tmpfile.path, 'w')
    file.puts to_dot(root_item, deep, current_item)
    file.close
    puts "saved to tmp file: "+tmpfile.path
    `dot -Tpng #{tmpfile.path}`
  end

  #fixes a problem with missing units, which causes Firefox to incorrectly display.
  #this will fail if the font-size set is not a whole integer  
  def post_process_svg svg
    svg = svg.gsub(".00;", ".00px;")
    orig_header = svg.match(/<svg([^>]*)>/).to_s #remember header with namespace

    parser = LibXML::XML::Parser.string(svg)
    document = parser.parse
    document.root.namespaces.default_prefix = 'svg'

    #only display svg if number of node > 1
    number_of_node = document.find("svg:g//svg:g").collect.count
    return "" if number_of_node <= 1

    document.find("svg:g//svg:g").each do |node|
      title = node.find_first("svg:title").content
      unless title.include?("--")
        object_class, object_id = title.split("_")
        if ["Sop", "Model", "DataFile", "Publication", "Study", "Assay", "Investigation"].include?(object_class)
          a = node.find_first(".//svg:a")
          polygon = a.find_first(".//svg:polygon")
          points = polygon.attributes["points"]
          points = points.split(" ")
          x2 = nil
          y2 = nil
          if points.size == 5
            x2, y2 = points[1].split(",")
          else
            x2, y2 = points[4].split(",")
          end
          #ADD THE CORRECT AVATAR, HERE
          if self.respond_to?("avatar")
            object = eval("#{object_class}.find(#{object_id})")
            av_url = avatar(object, 14, true).match(/src=\"[^\"]*\"/).to_s.gsub("src=", "").gsub("\"", "")
            rect_node = LibXML::XML::Node.new("rect width=\"18\" height=\"18\" x=\"#{x2.to_f + 3}\" y=\"#{y2.to_f + 3}\" style=\"fill: rgb(255,255,255);stroke:rgb(120,120,120);\"")
            image_node = LibXML::XML::Node.new("image width=\"14\" height=\"14\" x=\"#{x2.to_f + 5}\" y=\"#{y2.to_f + 5}\" xlink:href=\"#{av_url}\"")
            a<<(rect_node)
            a<<(image_node)
            a.find(".//svg:text").collect do |node|
              text_position_x =node.attributes['x'].to_i
              text_position_x +=10
              node.attributes['x'] = text_position_x.to_s
            end
          end

        end
      end
    end

    svg_el = document.find_first("//svg:svg")
    svg_el.attributes["width"]="500pt"
    svg = document.to_s

    if (Rails.env == 'test')
      #strip out the <?xml ..?> as the test parser doesn't like this and spits out millions of warnings
      svg = svg.gsub(/<\?xml.*\?>/,"")
    end

    svg
  end

  #fixes a problem with missing units, which causes Firefox to incorrectly display.
  #this will fail if the font-size set is not a whole integer
  def post_process_svg_for_publishing svg
    svg = svg.gsub(".00;", ".00px;")
    orig_header = svg.match(/<svg([^>]*)>/).to_s #remember header with namespace

    parser = LibXML::XML::Parser.string(svg)
    document = parser.parse
    document.root.namespaces.default_prefix = 'svg'

    object_types = ["Sop", "Model", "DataFile", "Study", "Assay", "Investigation"]
    document.find("svg:g//svg:g").each do |graphic_object|
      title = graphic_object.find_first("svg:title").content
      #node
      unless title.include?("--")
        object_class, object_id = title.split("_")
        #only keeps the nodes of the items in the object_types
        if object_types.include?(object_class)
          object = eval("#{object_class}.find(#{object_id})")
          a = graphic_object.find_first(".//svg:a")

          polygon = a.find_first(".//svg:polygon")

          points = polygon.attributes["points"]
          points = points.split(" ")
          x2 = nil
          y2 = nil
          if points.size == 5
            x2, y2 = points[1].split(",")
          else
            x2, y2 = points[4].split(",")
          end

          process_polygon_frame_color(polygon,object)

          rect_node_background_color ||= object.can_publish? ? 'white' : 'gray'
          rect_node = LibXML::XML::Node.new("rect onclick=\"switchColor(this.id)\" id=\"#{object_class}_#{object_id}\" class=\"#{object_class}_#{object_id}\" width=\"18\" height=\"18\" x=\"#{x2.to_f + 3}\" y=\"#{y2.to_f + 3}\" style=\"fill: #{rect_node_background_color};stroke:rgb(120,120,120);\"")
          graphic_object<<(rect_node)

          a.find(".//svg:text").collect do |node|
            text_position_x =node.attributes['x'].to_i
            text_position_x +=10
            node.attributes['x'] = text_position_x.to_s
          end
        else
          graphic_object.remove!
        end
      #edge
      else
        edge1_title, edge2_title = title.split("--")
        object1_class, object1_id = edge1_title.split("_")
        object2_class, object2_id = edge2_title.split("_")
        #only keeps the nodes of the items in the object_types
        unless object_types.include?(object1_class) && object_types.include?(object2_class)
          graphic_object.remove!
        end
      end
    end

    svg_el = document.find_first("//svg:svg")
    svg = document.to_s

    if (Rails.env == 'test')
      #strip out the <?xml ..?> as the test parser doesn't like this and spits out millions of warnings
      svg = svg.gsub(/<\?xml.*\?>/,"")
    end

    svg
  end

  def process_polygon_frame_color(polygon,object)
    if !polygon.attributes['style'].blank?
      style = polygon.attributes['style']
      filled_color = style.split(';').select{|fc| fc.match('fill:')}.first
      polygon.attributes['style']=filled_color
    end
    if @selected_items.include?(object)
      polygon.attributes['stroke'] = 'darkgreen'
      polygon.attributes['stroke-width'] = "3"
      rect_node_background_color = 'darkgreen'
    else
      polygon.attributes['stroke'] = 'black'
      polygon.attributes['stroke-width'] = "1"
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
class SeekNode < DotGenerator::Node
  def hide
    self.attributes = attributes.merge :label => 'Hidden Item', :tooltip => 'Hidden Item',
                                       :fontsize => 6, :fillcolor => 'lightgray',
                                       :target => nil, :URL => nil
  end

  def label
    item.title
  end

  def include_defaults
    super
    hide unless item.can_view?
  end

  def to_s
    #hidden items with no real child nodes that want to display themselves, are removed
    @string ||= if !item.can_view? and child_nodes.collect(&:to_s).join.blank? then "" else super end
  end

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
    item.studies
  end
end

class StudyNode < SeekNode
  def children
    item.assays
  end
end

class PublicationNode < SeekNode
  def as_dot
    publication = item
    dot = ""
    pub_node = SeekNode.node_for(publication)
    if publication.related_assays.empty?
      dot << pub_node.to_s
    else
      #publications want to display assays nodes.. but with only this publication showing as a child
      #so I create a local subclass, which does exactly that.
      assay_viewer = Class.new(AssayNode)
      assay_viewer.class_eval { define_method(:child_nodes) { [pub_node] } }
      publication.related_assays.each do |assay|
        dot << assay_viewer.new(assay).to_s
      end
    end
    (publication.related_data_files + publication.related_models).each do |asset|
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
    current.respond_to?(:contributor) && item.respond_to?(:related_publications) ? item.related_publications : []
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
    deep ? item.assay_assets + item.related_publications + item.samples : []
  end
end



#AssayAssetNode is only used for children of Assay
class AssayAssetNode < AssetNode
  def initialize assay_asset
    @assay_asset = assay_asset
    super assay_asset.asset
  end

  def edge other, attributes={}
    if @assay_asset.relationship_type
      super other, {:label => @assay_asset.relationship_type.title, :fontsize => 9}.merge(attributes)
    else
      super
    end
  end
end

class SampleNode < SeekNode
  def children
    [item.specimen]
  end
end

