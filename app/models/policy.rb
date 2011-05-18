class Policy < ActiveRecord::Base
  
  has_many :assets,
           :dependent => :nullify,
           :order => "resource_type ASC"
  
  has_many :permissions,
           :dependent => :destroy,
           :order => "created_at ASC",
           :autosave => true,
           :after_add => proc {|policy, perm| perm.policy = policy}
  
  validates_presence_of :sharing_scope, :access_type

  validates_numericality_of :sharing_scope, :access_type
  
  alias_attribute :title, :name
  
  
  # *****************************************************************************
  #  This section defines constants for "sharing_scope" and "access_type" values
  
  # NB! It is critical to all algorithms using these constants, that the latter
  # have their integer values increased along with the access they provide
  # (so, for example, "editing" should have greated value than "viewing")
  
  # In other words, this means that for both(!) sharing_scope and access_type 
  # constants it is crucial that order of these (imposed by their integer values)
  # is preserved
  
  # sharing_scope
  PRIVATE = 0
  CUSTOM_PERMISSIONS_ONLY = 1
  ALL_SYSMO_USERS = 2
  ALL_REGISTERED_USERS = 3
  EVERYONE = 4
  
  # access_type
  DETERMINED_BY_GROUP = -1  # used for whitelist/blacklist (meaning that it doesn't matter what value this field has)
  NO_ACCESS = 0             # i.e. only for anyone; only owner has access
  VISIBLE = 1               # visible only
  ACCESSIBLE = 2            # accessible and visible
  EDITING = 3               # accessible, visible and editing
  MANAGING = 4              # any actions that owner of the asset can perform (including "destroy"ing)
    
  # "true" value for flag-type fields
  TRUE_VALUE = 1
  FALSE_VALUE = 0
  # *****************************************************************************
  
  #makes a copy of the policy, and its associated permissions.
  def deep_copy
    copy=self.clone
    self.permissions.each {|p| copy.permissions << p.clone}
    return copy
  end

  #checks that there are permissions for the provided contributor, for the access_type (or higher)
  def permission_granted?(contributor,access_type)
    permissions.detect{|p| p.contributor==contributor && p.access_type >= access_type}
  end

  def self.new_for_upload_tool(resource, recipient)
    policy = resource.create_policy(:name               => 'auto',
                                    :sharing_scope      => Policy::CUSTOM_PERMISSIONS_ONLY,
                                    :access_type        => Policy::NO_ACCESS)
    policy.permissions.create :contributor_type => "Person", :contributor_id => recipient, :access_type => Policy::ACCESSIBLE
    return policy
  end

  def self.create_or_update_policy  resource, user, params
    resource.policy = (resource.policy || Policy.new).set_attributes_with_sharing(params[:sharing])
    resource.save
    resource.errors.full_messages.join('\n')
  end
  
  def set_attributes_with_sharing sharing
    # if no data about sharing is given, it should be some user (not the owner!)
    # who is editing the asset - no need to do anything with policy / permissions: return success
    returning self do |policy|
      if sharing
    
        # obtain parameters from sharing hash
        policy.sharing_scope = sharing[:sharing_scope]
        policy.access_type = ((policy.sharing_scope == Policy::CUSTOM_PERMISSIONS_ONLY) ? Policy::NO_ACCESS : sharing["access_type_#{sharing_scope}"])
        use_custom_sharing = ((policy.sharing_scope == Policy::CUSTOM_PERMISSIONS_ONLY) ? Policy::TRUE_VALUE : sharing["include_custom_sharing_#{sharing_scope}"]).to_i
        policy.use_whitelist = sharing[:use_whitelist]
        policy.use_blacklist = sharing[:use_blacklist]

    
        # NOW PROCESS THE PERMISSIONS

        # read the permission data from sharing
        unless sharing[:permissions].blank?
          contributor_types = ActiveSupport::JSON.decode(sharing[:permissions][:contributor_types])
          new_permission_data = ActiveSupport::JSON.decode(sharing[:permissions][:values])
        else
          contributor_types = []
          new_permission_data = {}
        end

        # NB! if "use_custom_sharing" is not set after the policy data was processed - this means that there can be
        # no more permissions: and any existing ones should be deleted; the line below ensures that the synchronisation
        # mechanism will "think" that no permission selections were made and all old ones need to be removed
        unless (use_custom_sharing == true || use_custom_sharing == Policy::TRUE_VALUE)
          new_permission_data = {}
        end


        # --- Synchronise All Permissions for the Policy ---
        # first delete or update any old memberships
        policy.permissions.each do |p|
          if permission_access = (new_permission_data[p.contributor_type.to_s].try :delete, p.contributor_id)
            p.access_type = permission_access
          else
            p.mark_for_destruction
          end
        end
    
    
        # now add any remaining new memberships
        contributor_types.try :each do |contributor_type|
          new_permission_data[contributor_type.to_s].try :each do |p|
            if policy.new_record? or !Permission.find :first, :conditions => {:contributor_type => contributor_type, :contributor_id => p[0], :policy_id => policy.id}
              p = policy.permissions.build :contributor_type => contributor_type, :contributor_id => p[0], :access_type => p[1]["access_type"]
            end
          end
        end

      end
    end
  end
  
  def self.create_or_update_default_policy(project, user, params)
    # this method will return an error message is something goes wrong (empty string in case of success)
    error_msg = ""
    
    # if no data about sharing is contained in params[], it should be some user (not the onwer!)
    # who is editing the asset - no need to do anything with policy / permissions: return success
    return error_msg unless params[:sharing]
    
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
    unless project.default_policy
      #last_saved_policy = Policy._default(current_user, nil) # second parameter ensures that this policy is not applied anywhere
      
      
      policy = Policy.new(:name => 'auto',                          
                          :sharing_scope => sharing_scope,
                          :access_type => access_type,
                          :use_whitelist => use_whitelist,
                          :use_blacklist => use_blacklist)
      project.default_policy = policy  # by doing this the new policy object is saved implicitly too
      project.save
    else
       policy = project.default_policy
       #last_saved_policy = policy.clone # clone required, not 'dup' (which still works through reference, so the values in both get changed anyway - which is not what's needed here)
       
       policy.sharing_scope = sharing_scope
       policy.access_type = access_type
       policy.use_whitelist = use_whitelist
       policy.use_blacklist = use_blacklist
       policy.save
    end
    
    
    # NOW PROCESS THE PERMISSIONS
    # policy of an asset; pemissions will be applied to it
    policy = project.default_policy

    
    # read the permission data from params[]
    unless params[:sharing][:permissions].blank?
      contributor_types = ActiveSupport::JSON.decode(params[:sharing][:permissions][:contributor_types])
      new_permission_data = ActiveSupport::JSON.decode(params[:sharing][:permissions][:values])
    else
      contributor_types = []
      new_permission_data = {}
    end

    # NB! if "use_custom_sharing" is not set after the policy data was processed - this means that there can be
    # no more permissions: and any existing ones should be deleted; the line below ensures that the synchronisation
    # mechanism will "think" that no permission selections were made and all old ones need to be removed
    unless (use_custom_sharing == true || use_custom_sharing == Policy::TRUE_VALUE)
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
    
  # returns a default policy for a project
  # (all the related permissions will still be linked to the returned policy)
  def self.project_default(project)
    # if the default project policy isn't set, NIL will be returned - and the caller
    # has to perform further actions in such case
    return project.default_policy
  end
  
  def self.private_policy
    policy = Policy.new(:name => "default private",                        
                        :sharing_scope => PRIVATE,
                        :access_type => NO_ACCESS,
                        :use_whitelist => false,
                        :use_blacklist => false)
                        
    return policy
  end

  #The default policy to use when creating authorized items if no other policy is specified
  def self.default
    private_policy
  end
   
  # translates access type codes into human-readable form
  def self.get_access_type_wording(access_type, resource=nil)
    case access_type
      when Policy::DETERMINED_BY_GROUP
        return "Individual access rights for each member"
      when Policy::NO_ACCESS
        return "No access"
      when Policy::VISIBLE
        return resource.try(:is_downloadable?) ? "View summary only" : "View summary"
      when Policy::ACCESSIBLE
        return resource.try(:is_downloadable?) ? "View summary and get contents" : "View summary"
      when Policy::EDITING
        return resource.try(:is_downloadable?) ? "View and edit summary and contents" : "View and edit summary"
      when Policy::MANAGING
        return "Manage"
      else
        return "Invalid access type"
    end
  end
  
  
  # extracts the "settings" of the policy, discarding other information
  # (e.g. contributor, creation time, etc.)
  def get_settings
    settings = {}
    settings['sharing_scope'] = self.sharing_scope
    settings['access_type'] = self.access_type
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
