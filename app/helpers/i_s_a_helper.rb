require 'tempfile'

module ISAHelper
  FILL_COLOURS = { 'Sop' => '#7ac5cd', # cadetblue3
                   'Model' => '#cdcd00', # yellow3
                   'DataFile' => '#eec591', # burlywood2
                   'Investigation' => '#E6E600',
                   'Study' => '#B8E62E',
                   'Assay' => { 'EXP' => '#64b466', 'MODEL' => '#92CD00' },
                   'Publication' => '#84B5FD',
                   'Presentation' => '#8ee5ee', # cadetblue2
                   'HiddenItem' => '#d3d3d3' } # lightgray

  BORDER_COLOURS = { 'Sop' => '#619da4',
                     'Model' => '#a4a400',
                     'DataFile' => '#be9d74',
                     'Investigation' => '#9fba99',
                     'Study' => '#74a06f',
                     'Assay' => { 'EXP' => '#509051', 'MODEL' => '#74a400' },
                     'Publication' => '#6990ca',
                     'Presentation' => '#71b7be', # cadetblue2
                     'HiddenItem' => '#a8a8a8' }

  FILL_COLOURS.default = '#8ee5ee' # cadetblue2
  BORDER_COLOURS.default = '#71b7be'

  def cytoscape_elements(elements_hash)
    elements = cytoscape_edge_elements(elements_hash) + cytoscape_node_elements(elements_hash)
    # aggregate_hidden_nodes(elements)
  rescue Exception => e
    raise e if Rails.env.development?
    Rails.logger.error("Error generating nodes and edges for the graph - #{e.message}")
    { error: 'error' }
  end

  private

  def cytoscape_node_elements(hash)
    elements = []
    hash[:nodes].each do |node|
      item = node.object
      item_type = item.class.name
      data = { id: node_id(item) }

      if node.can_view?
        if item.respond_to?(:description)
          data['description'] = truncate(h(item.description), length: 500)
        else
          data['description'] = ''
        end

        if data['description'].blank?
          data['description'] = item.is_a?(Publication) ? 'No abstract' : 'No description'
        end

        data['name'] = truncate(h(item.title), length: 110)
        data['fullName'] = h(item.title)
        avatar = resource_avatar_path(item) || icon_filename_for_key("#{item.class.name.downcase}_avatar")
        data['imageUrl'] = asset_path(avatar)
        data['url'] = polymorphic_path(item)

        if item.is_a?(Assay) # distinquish two assay classes
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

      elements << { group: 'nodes', data: data, classes: 'resource' }

      # If this node has children, but they aren't included in the set of nodes, create an info node that will load the children
      #  when clicked
      actual_child_count = hash[:edges].count { |source, _| source == item }
      next unless node.child_count > actual_child_count
      cc_id = child_count_id(item)
      elements << { group: 'nodes', data: { id: cc_id,
                                            name: "Show #{node.child_count - actual_child_count} more",
                                            url: polymorphic_path(item, action: :isa_children) },
                    classes: 'child-count' }
      elements << { group: 'edges', data: { id: "#{cc_id}-edge",
                                            source: data[:id],
                                            target: cc_id } }
    end

    elements
  end

  def cytoscape_edge_elements(hash)
    elements = []
    hash[:edges].each do |edge|
      source_item, target_item = edge
      source = node_id(source_item)
      target = node_id(target_item)
      target_type = target_item.class.name
      e_id = edge_id(source_item, target_item)
      name = edge_label(source_item, target_item)

      elements << { group: 'edges',
                    data: { id: e_id,
                            name: name,
                            source: source,
                            target: target,
                            faveColor: BORDER_COLOURS.default },
                    classes: 'resource-edge'
      }
    end
    elements
  end

  def edge_element(id, name, source, target, fave_color)
    { group: 'edges',
      data: { id: id,
              name: name,
              source: source,
              target: target,
              faveColor: fave_color }
    }
  end

  def edge_label(source, target)
    source_type = source.class.name
    source_id = source.id
    target_type = target.class.name
    target_id = target.id

    label_data = []
    if source_type == 'Assay' && (target_type == 'DataFile' || target_type == 'Sample')
      assay_asset = AssayAsset.where(['assay_id=? AND asset_id=?', source_id, target_id]).first
      if assay_asset
        label_data << assay_asset.relationship_type.title if assay_asset.relationship_type
        label_data << direction_name(assay_asset.direction) if assay_asset.direction && assay_asset.direction != 0
      end
    elsif source_type == 'Sample' && target_type == 'Assay'
      assay_asset = AssayAsset.where(['assay_id=? AND asset_id=?', target_id, source_id]).first
      if assay_asset
        label_data << direction_name(assay_asset.direction) if assay_asset.direction && assay_asset.direction != 0
      end
    end
    label_data.join(', ')
  end

  def tree_json(hash)
    objects = hash[:nodes].map(&:object)
    real_edges = hash[:edges].select { |e| objects.include?(e[0]) }

    roots = hash[:nodes].select do |n|
      real_edges.none? { |_parent, child| child == n.object }
    end

    nodes = roots.map { |root| tree_node(hash, root.object) }.flatten

    nodes.to_json
  end

  def tree_node(hash, object)
    child_edges = hash[:edges].select do |parent, _child|
      parent == object
    end

    node = hash[:nodes].detect { |n| n.object == object }

    entry = {
      id: unique_node_id(object),
      data: { loadable: false },
      li_attr: { 'data-node-id' => node_id(object) },
      children: []
    }

    if node.can_view?
      entry[:text] = object.title
      entry[:icon] = asset_path(resource_avatar_path(object) || icon_filename_for_key("#{object.class.name.downcase}_avatar"))
    else
      entry[:text] = 'Hidden item'
      entry[:a_attr] = { class: 'hidden-leaf none_text' }
    end

    if node.child_count > 0
      if node.child_count > child_edges.count
        entry[:children] << {
          id: unique_child_count_id(object),
          parent: entry[:id],
          text: "Show #{node.child_count - child_edges.count} more",
          a_attr: { class: 'child-count-leaf' },
          li_attr: { 'data-node-id' => child_count_id(object) },
          data: { child_count: true }
        }
      end

      entry[:state] = { opened: true }
    else
      entry[:state] = { opened: false }
    end

    entry[:children] += child_edges.map { |c| tree_node(hash, c[1]) }

    entry
  end

  def aggregate_hidden_nodes(elements)
    nodes = elements.select { |e| e[:group] == 'nodes' }
    edges = elements.select { |e| e[:group] == 'edges' }

    hidden_nodes = nodes.select { |n| n[:data]['type'] == 'Hidden' } # Get hidden nodes
    hidden_nodes.select! { |n| edges.none? { |e| e[:data][:source] == n[:data][:id] } } # Filter out ones that have children
    hidden_nodes.select! { |n| edges.count { |e| e[:data][:target] == n[:data][:id] } == 1 } # Filter out ones that have multiple parents

    # Group the nodes by their parent
    groups = hidden_nodes.group_by do |n|
      edges.detect { |e| e[:data][:target] == n[:data][:id] }[:data][:source]
    end

    groups.each do |_group, node_list|
      next unless node_list.length > 1
      aggregate = node_list.pop
      aggregate[:data]['name'] = "#{node_list.length + 1} hidden items"
      node_ids = node_list.map { |n| n[:data][:id] }
      elements.delete_if { |e| node_ids.include?(e[:data][:target]) }
      elements -= node_list
    end

    elements
  end

  private

  def node_id(object)
    "#{object.class.name}-#{object.id}"
  end

  def unique_node_id(object)
    "#{node_id(object)}-#{rand(2**32).to_s(36)}"
  end

  def edge_id(source, target)
    "#{node_id(source)}-#{node_id(target)}"
  end

  def child_count_id(object)
    "#{node_id(object)}-child-count"
  end

  def unique_child_count_id(object)
    "#{child_count_id(object)}-#{rand(2**32).to_s(36)}"
  end
end
