class Policy < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  
  has_many :assets,
           :dependent => :nullify,
           :order => "resource_type ASC"
  
  has_many :permissions,
           :dependent => :destroy,
           :order => "created_at ASC"
  
  validates_presence_of :contributor, :sharing_scope, :access_type
  validates_numericality_of :sharing_scope, :access_type
  
  
  # *****************************************************************************
  #  This section defines constants for "sharing_scope" and "access_type" values
  
  # NB! It is critical to all algorithms using these constants, that the latter
  # have their integer values increased along with the access they provide
  # (so, for example, "editing" should have greated value than "viewing")
  
  # sharing_scope
  PRIVATE = 0
  CUSTOM_PERMISSIONS_ONLY = 1
  ALL_SYSMO_USERS = 2
  ALL_REGISTERED_USERS = 3
  EVERYONE = 4
  
  # access_type
  DETERMINED_BY_GROUP = -1  # used for whitelist/blacklist (meaning that it doesn't matter what value this field has)
  NO_ACCESS = 0             # i.e. only for anyone; only owner has access
  VIEWING = 1               # viewing only
  DOWNLOADING = 2           # downloading and viewing
  EDITING = 3               # downloading, viewing and editing
  OWNER = 4                 # any actions that owner of the asset can perform (including "destroy"ing)
  
  # *****************************************************************************
  
  
  def self.create_or_update_policy(resource, current_user, params)
    # this method will return an error message is something goes wrong (empty string in case of success)
    error_msg = ""
    
    # this variable will hold current settings of the policy in case something
    # goes wrong and a revert would be needed at some point
    last_saved_policy = nil
    
    
    # PROCESS THE POLICY FIRST
    unless resource.asset.policy
      #last_saved_policy = Policy._default(current_user, nil) # second parameter ensures that this policy is not applied anywhere
      
      policy = Policy.new(:name => 'auto',
                          :contributor_type => 'User',
                          :contributor_id => current_user.id,
                          :sharing_scope => 0, # TODO get this from parameter hash
                          :access_type => 0, # TODO
                          :use_custom_sharing => false, # TODO
                          :use_whitelist => false, # TODO
                          :use_blacklist => false) # TODO
      resource.asset.policy = policy  # by doing this the new policy object is saved implicitly too
      resource.asset.save
    else
       policy = resource.asset.policy
       #last_saved_policy = policy.clone # clone required, not 'dup' (which still works through reference, so the values in both get changed anyway - which is not what's needed here)
       
       policy.sharing_scope = 1 # TODO set all attributes into policy
       policy.access_type = 1 # TODO
       policy.use_custom_sharing = true # TODO
       policy.use_whitelist = true # TODO
       policy.use_blacklist = true # TODO
       policy.save
    end
    
    
    # NOW PROCESS THE PERMISSIONS
    # TODO
    # TODO
    
    
    # returns some message in case of errors (or empty string in case of success)
    return error_msg
  end
  
  
  # This method returns a "default" policy for a contributor
  # (that is it will contain default sharing options and default 
  #  permissions, if any are applicable)
  #
  # if "project" parameter not specified, system default policy
  # is used without any attempt to obtain default policy of the
  # project, where an asset that is supposed to be governed by
  # the default policy would be associated with
  def self.default(contributor, project=nil)
    rtn = nil
    
    if project
      rtn = self.project_default(project)
      
      # if a default policy for a project was set (i.e. not nil returned) - use that as a result;
      #
      # NB! This method is only to be used for reading, and the "default" policy read here should 
      # never be linked to anything; the standard use case is to read the default policy and show
      # its settings (and settings from all the linked permissions) in the "Sharing" option selector
      # screen - after which the "deep" copy of default policy-permissions structure can be recreated
      # on "saving" the resource, if necessary
      return rtn if rtn
    end
    
    # project default policy wasn't found or is not set, use system default
    rtn = self.system_default(contributor)
    
    return rtn
  end
  
  
  # returns a default policy for a project
  # (all the related permissions will still be linked to the returned policy)
  def self.project_default(project)
    # if the default project policy isn't set, NIL will be returned - and the caller
    # has to perform further actions in such case
    return project.default_policy
  end
  
  
  # returns a default system policy with "contributor" assigned as an admin;
  # as of now, default system policy is that assets are private to the uploader
  def self.system_default(contributor)
    policy = Policy.new(:name => "system default",
                        :contributor => contributor,
                        :sharing_scope => 0,
                        :access_type => 0,
                        :use_custom_sharing => false,
                        :use_whitelist => false,
                        :use_blacklist => false)
                        
    return policy
  end
  
  
  # extracts the "settings" of the policy, discarding other information
  # (e.g. contributor, creation time, etc.)
  def get_settings
    settings = {}
    settings['sharing_scope'] = self.sharing_scope
    settings['access_type'] = self.access_type
    settings['use_custom_sharing'] = self.use_custom_sharing
    settings['use_whitelist'] = self.use_whitelist
    settings['use_blacklist'] = self.use_blacklist
    return settings
  end
  
  
  # extract the "settings" from all permissions associated to the policy;
  # creates array containing 2-item arrays per each policy in the form:
  # [ ... , [ permission_id, {"contributor_id" => id, "contributor_type" => type, "access_type" => access} ]  , ...  ] 
  def get_permission_settings
    p_settings = []
    self.permissions.each do |p|
      # standard parameters for all contributor types
      params_hash = {}
      params_hash["contributor_id"] = p.contributor_id
      params_hash["contributor_type"] = p.contributor_type
      params_hash["access_type"] = p.access_type
      params_hash["contributor_name"] = (p.contributor_type == "Person" ? (p.contributor.first_name + " " + p.contributor.last_name) : p.contributor.name)
      
      # some of the contributor types will have special additional parameters
      case p.contributor_type
        when "FavouriteGroup"
          params_hash["whitelist_or_blacklist"] = [FavouriteGroup::WHITELIST_NAME, FavouriteGroup::BLACKLIST_NAME].include?(p.contributor.name)
      end
      
      p_settings << [ p.id, params_hash ]
    end
    
    return p_settings
  end
  
end
