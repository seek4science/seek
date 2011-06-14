class Asset < ActiveRecord::Base
  
  def self.classify_and_authorize(asset_array, should_perform_filtering_if_not_authorized=false, user_to_authorize=nil)
    results = {}
    
    asset_array.each do |asset|
      if should_perform_filtering_if_not_authorized
        # if asset is not authorized for viewing by this user, just skip it
        # (it's much faster to supply 'asset' instance instead of related resource)
        next unless asset.can_view? user_to_authorize
      end
      
      results[asset.class.name] = [] unless results[asset.class.name]
      results[asset.class.name] << asset
    end
    
    return results
  end
  
  #Works same as above method except takes a list of resources, in order to work with versioned models
  def self.classify_and_authorize_resources(resource_array, should_perform_filtering_if_not_authorized=false, user_to_authorize=nil)
    results = {}
    
    resource_array.each do |r|
      if should_perform_filtering_if_not_authorized
        # if asset is not authorized for viewing by this user, just skip it
        # (it's much faster to supply 'asset' instance instead of related resource)
        next unless r.can_view? user_to_authorize
      end
      
      # Fix version class names to be the class name of the versioned object
      class_name = r.class.name
      if class_name.end_with?("::Version")
        class_name = class_name.split("::")[0]
      end
      
      results[class_name] = [] unless results[class_name]
      results[class_name] << r
    end
    
    return results
  end
  
  #classify and authorize a set of objects of one type
  def self.classify_and_authorize_homogeneous_resources(resource_array, should_perform_filtering_if_not_authorized=false, user_to_authorize=nil)
    results = []
    
    resource_array.each do |r|
      if should_perform_filtering_if_not_authorized
        next unless r.can_view? user_to_authorize
      end
      
      results << r
    end
    
    return results
  end
end