class Asset < ActiveRecord::Base
  #belongs_to :contributor, :polymorphic => true
  
  belongs_to :resource, :polymorphic => true
  belongs_to :project
  belongs_to :policy
  
  has_many :assay_assets, :dependent => :destroy
  has_many :assays, :through => :assay_assets
  
  has_and_belongs_to_many :authors, :join_table => 'asset_authors', :class_name => 'Person', :association_foreign_key => 'author_id'
  
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
  
  #The order in which asset tabs appear
  ASSET_ORDER = ['Person', 'Project', 'Institution', 'Investigation', 'Study', 'Assay', 'DataFile', 'Model', 'Sop','SavedSearch']

  def contributor
    self.resource.contributor
  end

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
  
  #Works same as above method except takes a list of resources, in order to work with versioned models
  def self.classify_and_authorize_resources(resource_array, should_perform_filtering_if_not_authorized=false, user_to_authorize=nil)
    results = {}
    
    resource_array.each do |r|
      if should_perform_filtering_if_not_authorized
        # if asset is not authorized for viewing by this user, just skip it
        # (it's much faster to supply 'asset' instance instead of related resource)
        next unless Authorization.is_authorized?("show", nil, r.asset, user_to_authorize)
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
  
  
  # checks if contributor is the owner of this asset
  def owner?(contributor)
    return self.contributor==contributor
  end
end
