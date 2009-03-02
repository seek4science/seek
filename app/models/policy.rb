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
  
  
  # "true" value for flag-type fields
  TRUE_VALUE = 1
  FALSE_VALUE = 0
  # *****************************************************************************
  
  
  def self.create_or_update_policy(resource, current_user, params)
    # this method will return an error message is something goes wrong (empty string in case of success)
    error_msg = ""
    
    # this variable will hold current settings of the policy in case something
    # goes wrong and a revert would be needed at some point
    last_saved_policy = nil
    
    # obtain parameters from params[] hash
    sharing_scope = params[:sharing][:sharing_scope].to_i
    access_type = ((sharing_scope == Policy::CUSTOM_PERMISSIONS_ONLY) ? Policy::NO_ACCESS : params[:sharing]["access_type_#{sharing_scope}"])
    use_custom_sharing = ((sharing_scope == Policy::CUSTOM_PERMISSIONS_ONLY) ? Policy::TRUE_VALUE : params[:sharing]["include_custom_sharing_#{sharing_scope}"])
    use_whitelist = params[:sharing][:use_whitelist]
    use_blacklist = params[:sharing][:use_blacklist]
    
    
    # PROCESS THE POLICY FIRST
    unless resource.asset.policy
      #last_saved_policy = Policy._default(current_user, nil) # second parameter ensures that this policy is not applied anywhere
      
      
      policy = Policy.new(:name => 'auto',
                          :contributor_type => 'User',
                          :contributor_id => current_user.id,
                          :sharing_scope => sharing_scope,
                          :access_type => access_type,
                          :use_custom_sharing => use_custom_sharing,
                          :use_whitelist => use_whitelist,
                          :use_blacklist => use_blacklist)
      resource.asset.policy = policy  # by doing this the new policy object is saved implicitly too
      resource.asset.save
    else
       policy = resource.asset.policy
       #last_saved_policy = policy.clone # clone required, not 'dup' (which still works through reference, so the values in both get changed anyway - which is not what's needed here)
       
       policy.sharing_scope = sharing_scope
       policy.access_type = access_type
       policy.use_custom_sharing = use_custom_sharing
       policy.use_whitelist = use_whitelist
       policy.use_blacklist = use_blacklist
       policy.save
    end
    
    
    # NOW PROCESS THE PERMISSIONS
    # policy of an asset; pemissions will be applied to it
    policy = resource.asset.policy
    
    # read the permission data from params[]
    contributor_types = ActiveSupport::JSON.decode(params[:sharing][:permissions][:contributor_types])
    new_permission_data = ActiveSupport::JSON.decode(params[:sharing][:permissions][:values])
    
    # NB! if "use_custom_sharing" is not set after the policy data was processed - this means that there can be
    # no more permissions: and any existing ones should be deleted; the line below ensures that the synchronisation
    # mechanism will "think" that no permission selections were made and all old ones need to be removed 
    unless (policy.use_custom_sharing == true || policy.use_custom_sharing == Policy::TRUE_VALUE)
      new_permission_data = {}
    end
    
    
    # --- Synchronise All Permissions for the Policy ---
    # first delete any old memberships that are no longer valid
    changes_made = false
    policy.permissions.each do |p|
      unless (new_permission_data["#{p.contributor_type}"] && new_permission_data["#{p.contributor_type}"][p.contributor_id])
        p.destroy
        changes_made = true
      end
    end
    # this is required to leave the association of "policy" with its permissions in the correct state; otherwise exception is thrown
    policy.reload if changes_made
    
    
    # update the remaining old permissions if the access type has changed for them
    policy.permissions.each do |p|
      unless p.access_type == new_permission_data["#{p.contributor_type}"][p.contributor_id]["access_type"].to_i
        p.access_type = new_permission_data["#{p.contributor_type}"][p.contributor_id]["access_type"].to_i
        p.save!
      end
    end
    
    
    # now add any remaining new memberships
    if contributor_types && contributor_types.length > 0
      contributor_types.each do |contributor_type|
        if new_permission_data.has_key?(contributor_type)
          new_permission_data["#{contributor_type}"].each do |p|
            unless (found = Permission.find(:first, :conditions => {:contributor_type => contributor_type, :contributor_id => p[0], :policy_id => policy.id}))
              Permission.create(:contributor_type => contributor_type, :contributor_id => p[0], :access_type => p[1]["access_type"], :policy_id => policy.id)
            end
          end
        end
      end
    end
    
    # --- Synchronisation is Finished ---
    
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
  
  
  # translates access type codes into human-readable form
  def self.get_access_type_wording(access_type)
    case access_type
      when Policy::DETERMINED_BY_GROUP
        return "individual access rights for each member"
      when Policy::NO_ACCESS
        return "no access"
      when Policy::VIEWING
        return "viewing only"
      when Policy::DOWNLOADING
        return "viewing and downloading only"
      when Policy::EDITING
        return "viewing, downloading and editing"
      when Policy::OWNER
        return "owner access rights"
      else
        return "invalid access type"
    end
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
