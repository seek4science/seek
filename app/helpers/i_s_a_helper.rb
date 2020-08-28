require 'tempfile'

module ISAHelper
  OLD_FILL_COLOURS = {
      'Sop' => '#7AC5CD', # cadetblue3
      'Model' => '#CDCD00', # yellow3
      'DataFile' => '#EEC591', # burlywood2
      'Investigation' => '#E6E600',
      'Study' => '#B8E62E',
      'Assay' =>'#64B466',
      'Publication' => '#84B5FD',
      'Presentation' => '#8EE5EE', # cadetblue2
      'HiddenItem' => '#D3D3D3'
  } # lightgray

  NEW_FILL_COLOURS = {
      'Programme' => '#90A8FF',
      'Project' => '#85D6FF',
      'Investigation' => '#D6FF00',
      'Study' => '#96ED29',
      'Assay' =>'#52D155',
      'Publication' => '#CBB8FF',
      'DataFile' => '#FFC382',
      'Document' => '#D5C8A8',
      'Model' => '#F9EB57',
      'Sop' => '#CCE5FF',
      'Sample' => '#FFF2D5',
      'Presentation' => '#FFB2E4',
      'Event' => '#FF918E',
      'HiddenItem' => '#D3D3D3'
  }

  FILL_COLOURS = NEW_FILL_COLOURS
  FILL_COLOURS.default = '#8EE5EE' # cadetblue2

  def cytoscape_elements(elements_hash)
    cytoscape_edge_elements(elements_hash) + cytoscape_node_elements(elements_hash)
    # aggregate_hidden_nodes(elements)
  rescue Exception => e
    raise e if Rails.env.development?
    Rails.logger.error("Error generating nodes and edges for the graph - #{e.message}")
    { error: 'error' }
  end

  def modal_isa_png()
    modal_options = {id: 'modal-exported-png', size: 'xl', 'data-role' => 'modal-isa-graph-png'}

    modal_title = 'Export PNG'

    modal(modal_options) do
      modal_header(modal_title) +
          modal_body do
            #content_tag(:button, 'save',id:'save-exported-png') +
            content_tag(:p,'Click below to download a copy of the image') +
            button_link_to('Download', 'download', '#', id:'save-exported-png') +
            content_tag(:br) +
            content_tag(:img, '',id: 'exported-png', style:'max-width:1200px')
          end
    end
  end

  def cytoscape_node_elements(hash)
    elements = []
    hash[:nodes].each do |node|
      item = node.object
      item_type = item.is_a?(Seek::ObjectAggregation) ? "#{item.type} collection" : item.class.name
      data = { id: node_id(item) }

      data['seek_id'] = item.rdf_resource.to_s if item.respond_to?(:rdf_resource)
      if node.can_view?
        data['description'] = if item.respond_to?(:description)
                                truncate(item.description, length: 500)
                              else
                                ''
                              end

        if data['description'].blank?
          data['description'] = item.is_a?(Publication) ? 'No abstract' : 'No description'
        end

        data['name'] = truncate(item.title, length: 110)
        data['fullName'] = item.title
        avatar = resource_avatar_path(item) || icon_filename_for_key("#{item.class.name.downcase}_avatar")
        data['imageUrl'] = asset_path(avatar)
        data['url'] = item.is_a?(Seek::ObjectAggregation) ? polymorphic_path([item.object, item.type]) : polymorphic_path(item)
        data['type'] = item.is_a?(Assay) ? item.assay_class.title : item_type.humanize
        data['faveColor'] = FILL_COLOURS[item.is_a?(Seek::ObjectAggregation) ? item.type.to_s.singularize.capitalize : item.class.name] || FILL_COLOURS.default
      else
        data['name'] = 'Hidden item'
        data['fullName'] = data['name']
        data['type'] = 'Hidden'
        data['description'] = 'Hidden item'
        data['faveColor'] = FILL_COLOURS['HiddenItem']
      end

      elements << if node == hash[:nodes].first
                    { group: 'nodes', data: data, classes: 'resource' }
                  else
                    { group: 'nodes', data: data, classes: 'resource resource-small' }
                  end


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
                            faveColor: FILL_COLOURS.default },
                    classes: 'resource-edge' }
    end
    elements
  end

  def edge_element(id, name, source, target, fave_color)
    { group: 'edges',
      data: { id: id,
              name: name,
              source: source,
              target: target,
              faveColor: fave_color } }
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

  def tree_json(hash, root_item)
    objects = hash[:nodes].map(&:object)
    real_edges = hash[:edges].select { |e| objects.include?(e[0]) }

    roots = hash[:nodes].select do |n|
      real_edges.none? { |_parent, child| child == n.object }
    end

    nodes = roots.map { |root| tree_node(hash, root.object, root_item) }.flatten
    nodes.to_json
  end


  def add_permissions_to_tree_json (parent_node)

      parent_node.each do |node|

        node["li_attr"][:class] = "asset-node-row"
        node["a_attr"] = {}
        node["a_attr"][:class] = "asset-node"

        if !node["children"].nil? && node["children"].size > 0
        add_permissions_to_tree_json (node["children"])
        else
        end
        add_asset_permission_nodes(node)

      end
    parent_node
  end


  def add_asset_permission_nodes (parent_node)

    asset_type = parent_node["id"].split("-")[0]
    asset_id = parent_node["id"].split("-")[1].to_i

    # get asset instance
    asset =  asset_type.camelize.constantize.find(asset_id)
    parent_node["text"] = asset.title

    if asset_type == "Publication"
      parent_node["a_attr"] = {}
      parent_node["a_attr"][:class]= "no_checkbox"
    end

    permissions_array = get_permission(asset)
    parent_node["children"] = permissions_array + parent_node["children"]
    parent_node
  end

  def asset_node_json(resource_type, resource_items)

    parent = {
        id: resource_type+"-not_isa",
        data: { loadable: false },
        li_attr: {class:"asset-type-node"},
        a_attr: {},
        children: [],
        text: resource_type
    }

    resource_items.each do |item|

      entry_item = {
          id: unique_node_id(item),
          data: { loadable: false },
          li_attr: { 'data-node-id' => node_id(item), class:"asset-node-row"},
          a_attr: {class:"asset-node"},
          children: [] ,
          icon: asset_path(resource_avatar_path(item) || icon_filename_for_key("#{item.class.name.downcase}_avatar")),
          text: item.title + icon_link_to("", "new_window", item , options = {target:'blank',class:'asset-icon',:onclick => 'window.open(this.href, "_blank");'})
      }

      permissions_array = get_permission(item)
      entry_item[:children] = permissions_array
      parent[:children].append(entry_item)
    end
    parent
  end


  def create_policy_node(item, policy_text,sharing_policy_changed)

    entry = {
        id: unique_policy_node_id(item),
        data: { loadable: false },
        li_attr: { 'data-node-id' => "Permission-"+node_id(item), class:"hide_permission" },
        a_attr: { class:"permission-node #{sharing_policy_changed}"},
        children: [],
        text:policy_text
    }
    entry
  end

  def get_permission (item)

    policy =[]

    # policy
    downloadable = item.try(:is_downloadable?)
    policy_text = "#{Policy.get_access_type_wording(item.policy.access_type, downloadable)} by Public"
    sharing_policy_changed = (@batch_sharing_permission_changed && (@items_for_sharing.include? item) && !@policy_params[:access_type].nil?)? "sharing_permission_changed" : ""

    policy.append(create_policy_node(item,policy_text,sharing_policy_changed))

    #permission
    option = {:onclick => 'window.open(this.href, "_blank");'}

    item.policy.permissions.map do |permission|
      case permission.contributor_type
      when Permission::PROJECT
        m = Project.find(permission.contributor_id)
        policy_text ="#{Policy.get_access_type_wording(permission.access_type, downloadable)} by Project  #{link_to(h(m.title), m, option)}"
        sharing_policy_changed = @batch_sharing_permission_changed && (@items_for_sharing.include? item) ? PolicyHelper::permission_changed_item_class(permission, @policy_params) : ""
        policy.append(create_policy_node(item,policy_text,sharing_policy_changed))
      when Permission::WORKGROUP
        m = WorkGroup.find(permission.contributor_id)
        institution = Institution.find(m.institution_id)
        project = Project.find(m.project_id)
        policy_text ="#{Policy.get_access_type_wording(permission.access_type, downloadable)} by  #{link_to(h(project.title), project,option)}  @  #{link_to(h(institution.title), institution,option)}"
        sharing_policy_changed = @batch_sharing_permission_changed && (@items_for_sharing.include? item) ? PolicyHelper::permission_changed_item_class(permission, @policy_params) : ""
        policy.append(create_policy_node(item,policy_text,sharing_policy_changed))
      when Permission::INSTITUTION
        m = Institution.find(permission.contributor_id)
        policy_text ="#{Policy.get_access_type_wording(permission.access_type, downloadable)} by Institution  #{link_to(h(m.title), m,option)}"
        sharing_policy_changed = @batch_sharing_permission_changed && (@items_for_sharing.include? item) ? PolicyHelper::permission_changed_item_class(permission, @policy_params) : ""
        policy.append(create_policy_node(item,policy_text,sharing_policy_changed))
      when Permission::PERSON
        m = Person.find(permission.contributor_id)
        policy_text ="#{Policy.get_access_type_wording(permission.access_type, downloadable)} by People  #{link_to(h(m.title), m,option)}"
        sharing_policy_changed = @batch_sharing_permission_changed && (@items_for_sharing.include? item) ? PolicyHelper::permission_changed_item_class(permission, @policy_params) : ""
        policy.append(create_policy_node(item,policy_text,sharing_policy_changed))
      when Permission::PROGRAMME
        m = Programme.find(permission.contributor_id)
        policy_text ="#{Policy.get_access_type_wording(permission.access_type, downloadable)} by Programme  #{link_to(h(m.title), m,option)}"
        sharing_policy_changed = @batch_sharing_permission_changed && (@items_for_sharing.include? item) ? PolicyHelper::permission_changed_item_class(permission, @policy_params) : ""
        policy.append(create_policy_node(item,policy_text,sharing_policy_changed))
      end
    end
    policy
  end


  def tree_node(hash, object, root_item = nil)
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

    entry[:children] += child_edges.map { |c| tree_node(hash, c[1], root_item) }

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

      entry[:state] = { opened: false }
    else
      entry[:state] = { opened: false }
    end

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
    "#{object.class.name.gsub('::', '_')}-#{object.id}"
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

  def unique_policy_node_id(object)
    "Permission-#{node_id(object)}-#{rand(2**32).to_s(36)}"
  end


end
