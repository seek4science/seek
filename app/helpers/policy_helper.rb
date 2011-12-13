module PolicyHelper
  
  def policy_selection_options policies = nil, resource = nil, access_type = nil
    policies ||= [Policy::NO_ACCESS,Policy::VISIBLE,Policy::ACCESSIBLE,Policy::EDITING,Policy::MANAGING]
    options=""
    policies.delete(Policy::ACCESSIBLE) if resource && !resource.is_downloadable?
    policies.each do |policy|
      options << "<option value='#{policy}' #{"selected='selected'" if access_type == policy}>#{Policy.get_access_type_wording(policy, resource)} </option>"
    end      
    options
  end

  # return access_type of your project if this permission is available in the policy
  def your_project_access_type policy = nil, resource = nil
    unless policy.nil? or policy.permissions.empty? or resource.nil? or !(policy.sharing_scope == Policy::ALL_SYSMO_USERS)
      my_project_ids = if resource.class == Project then [resource.id] else resource.project_ids end
      my_project_perms = policy.permissions.select {|p| p.contributor_type == 'Project' and my_project_ids.include? p.contributor_id}
      access_types = my_project_perms.map(&:access_type)
      return access_types.first if access_types.all?{|acc| acc == access_types.first}
    end
  end

  #returns a message that there are additional advanced permissions for the resource outside of the provided scope, and if the policy matches the scope.
  def additional_advanced_permissions_included resource,scope
    if resource.policy && resource.policy.sharing_scope == scope
      additional = false

      if resource.policy.permissions.count>0
        if scope!=Policy::ALL_SYSMO_USERS
          additional=true
        else
          additional=true unless (resource.policy.permissions.collect{|p| p.contributor} - resource.projects).empty?
        end
      end

      "<span class='additional_permissions'>there are also additional Advanced Permissions defined below</span>" if additional
    end
  end
end