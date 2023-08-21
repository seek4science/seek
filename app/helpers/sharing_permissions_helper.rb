module SharingPermissionsHelper

  def get_permission_list (item)

    item_id = "#{item.class.name}_#{item.id}"

    policy = []

    # policy
    downloadable = item.try(:is_downloadable?)
    policy_text = "<strong>Public:</strong> #{Policy.get_access_type_wording(item.policy.access_type, downloadable)}."
    sharing_policy_changed = (@batch_sharing_permission_changed && (@items_for_sharing.include? item) && !@policy_params[:access_type].nil?)? "sharing_permission_changed" : ""

    policy.append("<div id=\"#{item_id}-Permission-Policy\" class=\"permission-node #{sharing_policy_changed}\">#{policy_text}</div>".html_safe)

    #permission
    option = { target: :_blank }
    item.policy.permissions.map do |permission|
      sharing_policy_changed = @batch_sharing_permission_changed && (@items_for_sharing.include? item) ? PolicyHelper::permission_changed_item_class(permission, @policy_params) : ""
      m = permission.contributor
      div_id = "#{item_id}-Permission-#{permission.contributor_type}-#{m.id}:"
      policy_text = "<strong>#{permission.contributor_type}  #{link_to(h(m.title), m, option)}:</strong>"
      case permission.contributor_type
      when Permission::WORKGROUP
        institution = Institution.find(m.institution_id)
        project = Project.find(m.project_id)
        policy_text = "<strong> #{link_to(h(project.title), project, option)}  @  #{link_to(h(institution.title), institution, option)}:</strong>"
      when Permission::PERSON
        policy_text = "<strong>#{link_to(h(m.title), m, option)}:</strong>"
      end
      policy_text += " #{Policy.get_access_type_wording(permission.access_type, downloadable)}."
      policy.append("<div id=\"#{div_id}\" class=\"permission-node #{sharing_policy_changed}\">#{policy_text}</div>".html_safe)
    end
    safe_join(policy)
  end

end
