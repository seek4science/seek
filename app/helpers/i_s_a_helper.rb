require 'tempfile'
require 'dot_generator'

module ISAHelper

  include DotGenerator

  FILL_COLOURS = {'Sop'=>"#7ac5cd", #cadetblue3
                  'Model'=>"#cdcd00", #yellow3
                  'DataFile'=>"#eec591", #burlywood2
                  'Investigation'=>"#C7E9C0",
                  'Study'=>"#91c98b",
                  'Assay'=>"#64b466",
                  'Publication'=>"#84B5FD",
                  'Presentation' => "#8ee5ee", #cadetblue2
                  'Sample' => "#ffa500", #orange
                  'Specimen' => "#ff0000", #red
                  'HiddenItem' => "#d3d3d3"} #lightgray

  BORDER_COLOURS = {'Sop'=>"#619da4",
                    'Model'=>"#a4a400",
                    'DataFile'=>"#be9d74",
                    'Investigation'=>"#9fba99",
                    'Study'=>"#74a06f",
                    'Assay'=>"#509051",
                    'Publication'=>"#6990ca",
                    'Presentation' => "#71b7be", #cadetblue2
                    'Sample' => "#cc8400",
                    'Specimen' => "#cc0000",
                    'HiddenItem' => "#a8a8a8"}

  FILL_COLOURS.default = "#8ee5ee" #cadetblue2
  BORDER_COLOURS.default = "#71b7be"

  def cytoscape_elements root_item,deep=true,current_item=nil
    begin
      current_item||=root_item
      dot_elements = to_dot(root_item,deep,current_item)
      elements = dot_elements.split(';')
      edges = elements.select{|e| e.include?('--')}
      nodes = edges.collect{|edge| edge.split('--')}.flatten.uniq
      nodes = nodes.each{|n| n.strip!}
      cytoscape_elements = cytoscape_node_elements(nodes) + cytoscape_edge_elements(edges)
      cytoscape_elements
    rescue Exception=>e
    end
  end

  private

  def cytoscape_node_elements nodes
    cytoscape_node_elements = []
    nodes.each do |node|
      item_type, item_id = node.split('_')
      item = item_type.constantize.find_by_id(item_id)
      if item.can_view?
        cytoscape_node_elements << {:group => 'nodes',
                                    :data => {:id => node,
                                              :name => truncate(item_type.humanize + ': ' + item.title),
                                              :full_title => ("<b>#{item_type.humanize}: </b>" +  h(item.title)) ,
                                              :path => polymorphic_path(item),
                                              :faveColor => (FILL_COLOURS[item_type] || FILL_COLOURS.default),
                                              :borderColor => (BORDER_COLOURS[item_type] || BORDER_COLOURS.default)}
        }
      else
        cytoscape_node_elements << {:group => 'nodes',
                                    :data => {:id => node,
                                              :name => 'Hidden item',
                                              :full_title => hidden_items_html([item], 'Hidden item'),
                                              :faveColor => (FILL_COLOURS['HiddenItem'] || FILL_COLOURS.default),
                                              :borderColor => (BORDER_COLOURS['HiddenItem'] || BORDER_COLOURS.default)}
        }
      end
    end
    cytoscape_node_elements
  end

  def cytoscape_edge_elements edges
    cytoscape_edge_elements = []
    edges.each do |edge|
      source, target = edge.split('--')
      source.strip!
      target.strip!
      edge.strip!
      target_type,target_id = target.split('_')
      target_item = target_type.constantize.find_by_id(target_id)
      if target_item.can_view?
        cytoscape_edge_elements << {:group => 'edges',
                                    :data => {:id => edge,
                                              :name => edge_label(source, target),
                                              :source => source,
                                              :target => target,
                                              :faveColor => (BORDER_COLOURS[target_type] || BORDER_COLOURS.default)}
        }
      else
        cytoscape_edge_elements << {:group => 'edges',
                                    :data => {:id => edge,
                                              :source => source,
                                              :name => edge_label(source, target),
                                              :target => target,
                                              :faveColor => (BORDER_COLOURS['HiddenItem'] || BORDER_COLOURS.default)}
        }
      end
    end
    cytoscape_edge_elements
  end

  def edge_label source,target
    source_type,source_id = source.split('_')
    target_type,target_id = target.split('_')

    label = ''
    if source_type == 'Assay' && target_type == 'DataFile'
      assay_asset = AssayAsset.where(["assay_id=? AND asset_id=?",
                        source_id, target_id]).first
      label << assay_asset.try(:relationship_type).try(:title).to_s
    end
    label
  end
end
