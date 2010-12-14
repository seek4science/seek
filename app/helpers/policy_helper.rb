module PolicyHelper
  
  def policy_selection_options policies = [Policy::NO_ACCESS,Policy::VISIBLE,Policy::ACCESSIBLE,Policy::EDITING,Policy::MANAGING]
    options=""
    policies.each do |policy|
      options << "<option value='#{policy}' >#{Policy.get_access_type_wording(policy)}</option>"
    end      
    options
  end  
  
end