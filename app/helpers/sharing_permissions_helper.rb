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
      div_id = 'case-not-found'
      case permission.contributor_type
      when Permission::PROJECT
        m = Project.find(permission.contributor_id)
        policy_text = "<strong>Project  #{link_to(h(m.title), m, option)}:</strong>"
        div_id = "#{item_id}-Permission-Project-#{m.id}:<strong>"
      when Permission::WORKGROUP
        m = WorkGroup.find(permission.contributor_id)
        institution = Institution.find(m.institution_id)
        project = Project.find(m.project_id)
        policy_text = "<strong> #{link_to(h(project.title), project, option)}  @  #{link_to(h(institution.title), institution, option)}:</strong>"
        div_id = "#{item_id}-Permission-Workgroup-#{m.id}"
      when Permission::INSTITUTION
        m = Institution.find(permission.contributor_id)
        policy_text = "<strong>Institution  #{link_to(h(m.title), m, option)}:</strong>"
        div_id = "#{item_id}-Permission-Institution-#{m.id}"
      when Permission::PERSON
        m = Person.find(permission.contributor_id)
        policy_text = "<strong>#{link_to(h(m.title), m, option)}:</strong>"
        div_id = "#{item_id}-Permission-Person-#{m.id}"
      when Permission::PROGRAMME
        m = Programme.find(permission.contributor_id)
        policy_text = "<strong>Programme  #{link_to(h(m.title), m, option)}:</strong>"
        div_id = "#{item_id}-Permission-Programme-#{m.id}"
      end
      policy_text += " #{Policy.get_access_type_wording(permission.access_type, downloadable)}."
      policy.append("<div id=\"#{div_id}\" class=\"permission-node #{sharing_policy_changed}\">#{policy_text}</div>".html_safe)
    end
    safe_join(policy)
  end

end
