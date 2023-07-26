module SharingPermissionsHelper

  ITEMS_NOT_IN_ISA_HASH = {
      "id": "not_isa-tree",
      "data": {
          "loadable": false
      },
      "li_attr": {
          class:"root-node"
      },
      "a_attr": {

      },
      "children": [
      ],
      "text": "Not in ISA",
      "state": {
          "opened": true
      }
  }

  ALL_INVESTIGATIONS_HASH = {
      "id": "isa-tree",
      "data": {
          "loadable": false
      },
      "li_attr": {
          class:"root-node"
      },
      "a_attr": {

      },
      "children": [
      ],
      "text": "ISA",
      "state": {
          "opened": true
      }
  }

  def build_tree_json(hash, root_item)

    objects = hash[:nodes].map(&:object)
    real_edges = hash[:edges].select { |e| objects.include?(e[0]) }

    roots = hash[:nodes].select do |n|
      real_edges.none? { |_parent, child| child == n.object }
    end

    nodes = roots.map { |root| create_tree_node(hash, root.object, root_item) }.flatten
    nodes.to_json
  end

  def create_tree_node(hash, object, root_item = nil)

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

      entry[:text] = object.title
      entry[:icon] = asset_path(resource_avatar_path(object) || icon_filename_for_key("#{object.class.name.downcase}_avatar"))

      filtered_child_edges = child_edges.reject { |c| (c[1].instance_of? Publication) || (c[1].instance_of?(Seek::ObjectAggregation))}
      child_edges_with_permission = filtered_child_edges.select { |c| c[1].can_manage? }

      unless child_edges_with_permission.blank?
        entry[:children] += child_edges_with_permission.map { |c| create_tree_node(hash, c[1], root_item) }
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
        entry[:state] = { opened: false }
      else
        entry[:state] = { opened: false }
      end
    entry
  end

  def add_permissions_to_tree_json (parent_node)

    parent_node.each do |node|
      node["li_attr"][:class] = "asset-node-row"
      node["a_attr"] = {}
      node["a_attr"][:class] = "asset-node"

      if !node["children"].nil? && node["children"].size > 0
        add_permissions_to_tree_json (node["children"])
      end
      add_asset_permission_nodes(node)
    end
    parent_node
  end

  def add_asset_permission_nodes(parent_node)
    asset_type = parent_node["id"].split("-")[0]
    asset_id = parent_node["id"].split("-")[1].to_i

    # get asset instance
    asset = safe_class_lookup(asset_type.camelize).find(asset_id)
    parent_node["text"] = "#{h(asset.title)}  #{icon_link_to("", "new_window", asset , options = {target:'blank',class:'asset-icon',:onclick => 'window.open(this.href, "_blank");'})}"

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
          text: "#{h(item.title)}  #{icon_link_to("", "new_window", item , options = {target:'blank',class:'asset-icon',:onclick => 'window.open(this.href, "_blank");'})}"
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


  private

  def unique_policy_node_id(object)
    "Permission-#{node_id(object)}-#{rand(2**32).to_s(36)}"
  end


end
