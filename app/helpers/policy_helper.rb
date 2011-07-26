module PolicyHelper
  
  def policy_selection_options policies = nil, resource = nil, access_type = nil
    policies ||= [Policy::NO_ACCESS,Policy::VISIBLE,Policy::ACCESSIBLE,Policy::EDITING,Policy::MANAGING]
    options=""
    policies.each do |policy|
      options << "<option value='#{policy}' #{"selected='selected'" if access_type == policy}>#{Policy.get_access_type_wording(policy, resource)} </option>" unless policy==Policy::ACCESSIBLE and resource and !resource.is_downloadable?
    end      
    options
  end

  # return access_type of your project if this permission is available in the policy
  def your_project_access_type policy = nil, resource = nil
    unless policy.nil? or policy.permissions.empty? or resource.nil? or !(policy.sharing_scope == Policy::ALL_SYSMO_USERS)
      policy.permissions.each do |permission|
        if (permission.contributor_type == 'Project') && (permission.contributor_id == (resource.class.name=="Project" ? resource.id : resource.project.try(:id)))
          return permission.access_type
        end
      end
    end
  end
end