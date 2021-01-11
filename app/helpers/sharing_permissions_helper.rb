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


  def remove_publication_node (parent_node)
    parent_node.each_with_index  do |node, index|
      if !node["children"].nil? && node["children"].size > 0
        remove_publication_node (node["children"])
      elsif node["id"].start_with?("Publication")
        parent_node.delete_at(index)
      end
    end
    parent_node
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


  def add_asset_permission_nodes (parent_node)

    asset_type = parent_node["id"].split("-")[0]
    asset_id = parent_node["id"].split("-")[1].to_i

    # get asset instance
    asset =  asset_type.camelize.constantize.find(asset_id)
    parent_node["text"] = "#{asset.title}  #{icon_link_to("", "new_window", asset , options = {target:'blank',class:'asset-icon',:onclick => 'window.open(this.href, "_blank");'})}"

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
          text: "#{item.title}  #{icon_link_to("", "new_window", item , options = {target:'blank',class:'asset-icon',:onclick => 'window.open(this.href, "_blank");'})}"
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