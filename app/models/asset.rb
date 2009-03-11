class Asset < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :resource, :polymorphic => true
  belongs_to :project
  
  belongs_to :policy

  # TODO
  # add all required validations here
  
  # classifies array of assets into a hash, where keys are the class names of the resources and
  # values - arrays of assets of that type; also, performs authorization when required
  #
  # Parameters:
  # - asset_array: array of assets to process
  # - should_perform_filtering_if_not_authorized: boolean value which indicates if the method
  #       needs to filter out assets that are not authorized for viewing by "user_to_authorize"
  # - user_to_authorize: user for which this asset hash will be rendered in the view
  def self.classify_and_authorize(asset_array, should_perform_filtering_if_not_authorized=false, user_to_authorize=nil)
    results = {}
    
    asset_array.each do |asset|
      if should_perform_filtering_if_not_authorized
        # if asset is not authorized for viewing by this user, just skip it
        # (it's much faster to supply 'asset' instance instead of related resource)
        next unless Authorization.is_authorized?("show", nil, asset, user_to_authorize)
      end
      
      res = asset.resource
      results[res.class.name] = [] unless results[res.class.name]
      results[res.class.name] << res
    end
    
    return results
  end
  
  
  # this method will save the Asset, but will not cause 'updated_at' field to receive new value of Time.now
  def save_without_timestamping
    class << self
      def record_timestamps; false; end
    end
  
    save
  
    class << self
      remove_method :record_timestamps
    end
  end
  
  
  # checks if c_utor is the owner of this asset
  def owner?(c_utor)
    case self.contributor_type
      when "User"
        return (self.contributor_id == c_utor.id && self.contributor_type == c_utor.class.name)
      # TODO some new types of "contributors" may be added at some point - this is to cater for that in future
      # when "Network"
      #   return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s
    else
      # unknown type of contributor - definitely not the owner 
      return false
    end
  end
end
