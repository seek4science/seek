module PolicyHelper
  
  def policy_selection_options policies = nil, resource = nil, access_type = nil
    policies ||= [Policy::NO_ACCESS,Policy::VISIBLE,Policy::ACCESSIBLE,Policy::EDITING,Policy::MANAGING]
    options=""
    policies.each do |policy|
      options << "<option value='#{policy}' #{"selected='selected'" if access_type == policy}>#{Policy.get_access_type_wording(policy, resource)} </option>" unless policy==Policy::ACCESSIBLE and resource and !resource.is_downloadable?
    end      
    options
  end

  #check if the sharing scope is ALL_SYSMO_USERS and permission is your project
  def share_with_your_project? policy = nil, resource = nil
    unless policy.nil? or policy.permissions.empty? or resource.nil?
      if (policy.sharing_scope == Policy::ALL_SYSMO_USERS) && (policy.permissions.length == 1) &&
      (policy.permissions.first.contributor_type == 'Project') && (policy.permissions.first.contributor_id == resource.project.id)
        true
      else
        false
      end
    else
      false
    end
  end
end