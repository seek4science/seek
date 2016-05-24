module PolicyHelper
  
  def policy_selection_options policies = nil, resource = nil, access_type = nil
    policies ||= [Policy::NO_ACCESS,Policy::VISIBLE,Policy::ACCESSIBLE,Policy::EDITING,Policy::MANAGING]
    unless resource.try(:is_downloadable?)
      policies.delete(Policy::ACCESSIBLE)
      if access_type == Policy::ACCESSIBLE
        #handle access_type = ACCESSIBLE, and !resource.is_downloadable?
        # In that case set access_type to VISIBLE
        access_type = Policy::VISIBLE
      end
    end
    options=""
    policies.each do |policy|
      options << "<option value='#{policy}' #{"selected='selected'" if access_type == policy}>#{Policy.get_access_type_wording(policy, resource.try(:is_downloadable?))} </option>"
    end
    options.html_safe
  end

  # return access_type of your project if this permission is available in the policy
  def your_project_access_type policy = nil, resource = nil
    unless policy.nil? or resource.nil? or !(policy.sharing_scope == Policy::ALL_USERS)
      unless policy.permissions.empty?
        my_project_ids = if resource.class == Project then [resource.id] else resource.project_ids end
        my_project_perms = policy.permissions.select {|p| p.contributor_type == 'Project' and my_project_ids.include? p.contributor_id}
        access_types = my_project_perms.map(&:access_type)
        return access_types.first if access_types.all?{|acc| acc == access_types.first}
      else
        policy.access_type
      end
    end
  end

  #returns a message that there are additional advanced permissions for the resource outside of the provided scope, and if the policy matches the scope.
  #if a resource has has Policy::ALL_USERS then it is concidered to have advanced permissions if it has permissions that includes contributors other than the associated projects
  def additional_advanced_permissions_included resource,scope
    if resource.respond_to?(:policy) && resource.policy && (resource.policy.sharing_scope == scope) && resource.has_advanced_permissions?
      "<span class='additional_permissions'>there are also additional Advanced Permissions defined below</span>".html_safe
    end
  end

  def policy_and_permissions_for_private_scope(permissions, privileged_people, resource_name)
    html = "<h3>You will share this #{resource_name.humanize} with:</h3>"
    html << "<p class='private'>You keep this #{resource_name.humanize.downcase} private (only visible to you)</p>"
    html << process_permissions(permissions, resource_name)
    html.html_safe
  end

  def policy_and_permissions_for_network_scope(policy, permissions, privileged_people, resource_name)
    html =''

    if policy.access_type != Policy::NO_ACCESS
      html << "<h3>You will share this #{resource_name.humanize} with:</h3>"
      html << "<p class='shared'>All the #{t('project')} members within the network can "
      html << Policy.get_access_type_wording(policy.access_type, resource_name.camelize.constantize.new().try(:is_downloadable?)).downcase
      html << "</p>"
      html << process_permissions(permissions, resource_name, true)
    else
      html << process_permissions(permissions, resource_name)
    end

    html.html_safe
  end

  def policy_and_permissions_for_public_scope(policy, permissions, privileged_people, resource_name, updated_can_publish_immediately, send_request_publish_approval)
    html = "<h3>You will share this #{resource_name.humanize} with:</h3>"
    html << "<p class='public'>All visitors (including anonymous visitors with no login) can #{Policy.get_access_type_wording(policy.access_type, resource_name.camelize.constantize.new()).downcase} </p>"
    if !updated_can_publish_immediately
      if send_request_publish_approval
         html << "<p class='gatekeeper_notice'>(An email will be sent to the Gatekeepers of the #{t('project').pluralize} associated with this #{resource_name.humanize} to ask for publishing approval. This #{resource_name.humanize} will not be published until one of the Gatekeepers has granted approval)</p>"
      else
         html << "<p class='gatekeeper_notice'>(You requested the publishing approval from the Gatekeepers of the #{t('project').pluralize} associated with this #{resource_name.humanize}, and it is waiting for the decision. This #{resource_name.humanize} will not be published until one of the Gatekeepers has granted approval)</p>"
      end
    end

    html << process_permissions(permissions, resource_name)
    html.html_safe
  end

  #check if there are overlapped people in permissions and of privileged_people
  #if yes, compare the access type of them
  #and keep the one with higher access type
  def uniq_people_permissions_and_privileged_people(permissions, privileged_people)
    uniq_permissions_by_contributor permissions

    people_from_permissions = permissions.select{|p| p.contributor_type == 'Person'}.collect(&:contributor)

    privileged_people.each do |key, value|
      value.each do |v|
        if people_from_permissions.include?(v)
          permission_index = permissions.index{ |p| p.contributor == v }
          access_type_from_permission = permissions[permission_index].access_type
          access_type_from_privileged_person = (key == 'creator') ? Policy::EDITING : Policy::MANAGING
          if (access_type_from_privileged_person >= access_type_from_permission)
            permissions.slice!(permission_index)
          else
            privileged_people[key].value.delete(v)
            if privileged_people[key].value.empty?
              privileged_people.delete(key)
            end
          end
        end
      end
    end
    [permissions, privileged_people]
  end

  def process_permissions permissions, resource_name, display_no_access=false
    #remove the permissions with access_type=NO_ACCESS
    permissions.select!{ |p| p.access_type != Policy::NO_ACCESS } unless display_no_access

    html = ''
    if !permissions.empty?
      html = "<h3>Fine-grained sharing permissions:</h3>"
      permissions.each do |p|
        contributor = p.contributor
        group_name = (p.contributor_type == 'WorkGroup') ? (h(contributor.project.title) + ' @ ' + h(contributor.institution.title)) : h(contributor.title)
        prefix_text = (p.contributor_type == 'Person') ? '' : ('Members of ' + p.contributor_type.underscore.humanize + ' ')
        html << "<p class='permission'>#{prefix_text + group_name}"
        html << ((p.access_type == Policy::DETERMINED_BY_GROUP || p.access_type == Policy::NO_ACCESS) ? ' have ' : ' can ')
        html << Policy.get_access_type_wording(p.access_type, resource_name.camelize.constantize.new().try(:is_downloadable?)).downcase
        html << "</p>"
      end
    end

    html.html_safe
  end

  def process_privileged_people privileged_people, resource_name
    html = ''
    unless privileged_people.blank?
      html << "<h3> Privileged people:</h3>"
      privileged_people.each do |key, value|
        value.each do |v|
          html << "<p class='privileged_person'>"
          if key == 'contributor'
            html << "#{h(v.name)} can #{Policy.get_access_type_wording(Policy::MANAGING, resource_name.camelize.constantize.new().try(:is_downloadable?)).downcase} as an uploader"
          elsif key == 'creators'
            html << "#{h(v.name)} can #{Policy.get_access_type_wording(Policy::EDITING, resource_name.camelize.constantize.new().try(:is_downloadable?)).downcase} as a creator"
          end
          html << "</p>"
        end
      end
    end

    html.html_safe
  end

  def uniq_permissions_by_contributor permissions
    #Choose the one which has the maximum access_type
    permissions.each_with_index do |p,index|
      permissions_with_the_same_contributor = permissions.select{|per| per.contributor == p.contributor}
      if permissions_with_the_same_contributor.size > 1
        max_access_type_per = permissions_with_the_same_contributor.max_by(&:access_type)
        permissions_with_the_same_contributor.delete(max_access_type_per)
        permissions_with_the_same_contributor.each {|p| permissions.delete(p)}
      end
    end

  end
end