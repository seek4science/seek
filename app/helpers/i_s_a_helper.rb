require 'tempfile'

module ISAHelper

  FILL_COLOURS = {'Sop'=>"#7ac5cd", #cadetblue3
                  'Model'=>"#cdcd00", #yellow3
                  'DataFile'=>"#eec591", #burlywood2
                  'Investigation'=>"#E6E600",
                  'Study'=>"#B8E62E",
                  'Assay'=> {'EXP'=>"#64b466",'MODEL'=>"#92CD00"},
                  'Publication'=>"#84B5FD",
                  'Presentation' => "#8ee5ee", #cadetblue2
                  'HiddenItem' => "#d3d3d3"} #lightgray

  BORDER_COLOURS = {'Sop'=>"#619da4",
                    'Model'=>"#a4a400",
                    'DataFile'=>"#be9d74",
                    'Investigation'=>"#9fba99",
                    'Study'=>"#74a06f",
                    'Assay'=> {'EXP'=>"#509051",'MODEL'=>"#74a400"},
                    'Publication'=>"#6990ca",
                    'Presentation' => "#71b7be", #cadetblue2
                    'HiddenItem' => "#a8a8a8"}

  FILL_COLOURS.default = "#8ee5ee" #cadetblue2
  BORDER_COLOURS.default = "#71b7be"

  def cytoscape_elements elements_hash
    begin
      cytoscape_node_elements(elements_hash) + cytoscape_edge_elements(elements_hash)
    rescue Exception=>e
      raise e if Rails.env.development?
      Rails.logger.error("Error generating nodes and edges for the graph - #{e.message}")
      {:error => 'error'}
    end
  end

  private

  def cytoscape_node_elements hash
    elements = []
    hash[:nodes].each do |node|
      item = node.object
      item_type = item.class.name
      data = { id: node_id(item) }

      if item.can_view?
        if item.respond_to?(:description)
          data['description'] = truncate(h(item.description), length: 500)
        else
          data['description'] = ''
        end
        
        if data['description'].blank?
          data['description'] = item.kind_of?(Publication) ? 'No abstract' : 'No description'
        end

        data['name'] = truncate(h(item.title), :length => 110)
        data['fullName'] = h(item.title)
        avatar = resource_avatar_path(item) || icon_filename_for_key("#{item.class.name.downcase}_avatar")
        data['imageUrl'] = asset_path(avatar)
        data['url'] = polymorphic_path(item)
        
        if item.kind_of?(Assay) #distinquish two assay classes
          assay_class_title = item.assay_class.title
          assay_class_key = item.assay_class.key
          data['type'] = assay_class_title
          data['faveColor'] = FILL_COLOURS[item_type][assay_class_key] || FILL_COLOURS.default
          data['borderColor'] = BORDER_COLOURS[item_type][assay_class_key] || BORDER_COLOURS.default
        else
          data['type'] = item_type.humanize
          data['faveColor'] = FILL_COLOURS[item_type] || FILL_COLOURS.default
          data['borderColor'] = BORDER_COLOURS[item_type] || BORDER_COLOURS.default
        end
      else
        data['name'] = 'Hidden item'
        data['fullName'] = data['name']
        data['type'] = 'Hidden'
        data['description'] = 'Hidden item'
        data['faveColor'] = FILL_COLOURS['HiddenItem'] || FILL_COLOURS.default
        data['borderColor'] = BORDER_COLOURS['HiddenItem'] || BORDER_COLOURS.default
      end

      # If this node has children, but they aren't included in the set of nodes, create an info node that will load the children
      #  when clicked
      actual_child_count = hash[:edges].select { |source, _| source == item }.count
      if node.child_count > actual_child_count
        cc_id = "#{data[:id]}-child-count"
        elements << { group: 'nodes', data: { id: cc_id,
                                              name: "Show #{node.child_count - actual_child_count} more",
                                              url: polymorphic_path(item, action: :isa_children) },
                      classes: 'child-count'}
        elements << { group: 'edges', data: { id: "#{cc_id}-edge",
                                              source: data[:id],
                                              target: cc_id } }
      end

      elements << { group: 'nodes', data: data, classes: 'resource' }
    end

    elements
  end

  def cytoscape_edge_elements hash
    elements = []
    hash[:edges].each do |edge|
      source_item, target_item = edge
      source = node_id(source_item)
      target = node_id(target_item)
      target_type = target_item.class.name
      e_id = edge_id(source_item, target_item)
      name = edge_label(source_item, target_item)

      if target_item.can_view?
        if target_item.kind_of?(Assay)
          fave_color = BORDER_COLOURS[target_type][target_item.assay_class.key] || BORDER_COLOURS.default
        else
          fave_color = BORDER_COLOURS[target_type] || BORDER_COLOURS.default
        end
      else
        fave_color = BORDER_COLOURS['HiddenItem'] || BORDER_COLOURS.default
      end

      elements << { group: 'edges',
                    data: { id: e_id,
                            name: name,
                            source: source,
                            target: target,
                            faveColor: fave_color },
                    classes: 'resource-edge'
      }
    end
    elements
  end

  def edge_element id, name, source, target, fave_color
    {:group => 'edges',
     :data => {:id => id,
               :name => name,
               :source => source,
               :target => target,
               :faveColor => fave_color}
    }
  end

  def edge_label source,target
    source_type,source_id = source.class.name, source.id
    target_type,target_id = target.class.name, target.id

    label_data = []
    if source_type == 'Assay' && (target_type == 'DataFile' || target_type == 'Sample')
      assay_asset = AssayAsset.where(["assay_id=? AND asset_id=?", source_id, target_id]).first
      if assay_asset
        label_data << assay_asset.relationship_type.title if assay_asset.relationship_type
        label_data << direction_name(assay_asset.direction) if (assay_asset.direction && assay_asset.direction != 0)
      end
    elsif source_type == 'Sample' && target_type == 'Assay'
      assay_asset = AssayAsset.where(["assay_id=? AND asset_id=?", target_id, source_id]).first
      if assay_asset
        label_data << direction_name(assay_asset.direction) if (assay_asset.direction && assay_asset.direction != 0)
      end
    end
    label_data.join(', ')
  end

  def tree_json(hash)
    roots = hash[:nodes].select do |n|
      hash[:edges].none? { |parent, child| child == n.object }
    end

    nodes = roots.map { |root| tree_node(hash, root.object) }

    nodes = nodes + hash[:edges].map do |edge|
      tree_node(hash, edge[1], node_id(edge[0]))
    end

    nodes.to_json
  end

  def tree_node(hash, object, parent_id = '#')
    child_edges = hash[:edges].select do |parent, child|
      parent == object
    end

    node = hash[:nodes].detect { |n| n.object == object }

    if object.can_view?
      entry = {
        id: node_id(object),
        text: object.title,
        parent: parent_id,
        icon: asset_path(resource_avatar_path(object) || icon_filename_for_key("#{object.class.name.downcase}_avatar"))
      }
    else
      entry = {
          id: node_id(object),
          text: 'Hidden item',
          parent: parent_id,
          a_attr: { class: 'hidden-leaf none_text' }
      }
    end

    if node.child_count > 0
      if node.child_count > child_edges.count
        # This is a little hack to show a node as "openable" despite having no children
        entry[:children] = true
        entry[:state] = { opened: false }
        entry[:data] = { loadable: true }
      else
        entry[:state] = { opened: true }
      end
    else
      entry[:state] = { opened: false }
    end

    entry
  end

  private

  def node_id(object)
    "#{object.class.name}-#{object.id}"
  end

  def edge_id(source, target)
    "#{node_id(source)}-#{node_id(target)}"
  end

end
