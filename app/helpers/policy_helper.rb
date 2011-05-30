module PolicyHelper
  
  def policy_selection_options policies = nil, resource = nil
    policies ||= [Policy::NO_ACCESS,Policy::VISIBLE,Policy::ACCESSIBLE,Policy::EDITING,Policy::MANAGING]
    options=""
    policies.each do |policy|
      options << "<option value='#{policy}' >#{Policy.get_access_type_wording(policy, resource)}</option>" unless policy==Policy::ACCESSIBLE and resource and !resource.is_downloadable?
    end      
    options
  end  
  
end