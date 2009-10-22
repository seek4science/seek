# SysMO: lib/authorization.rb
# Code taken from myExperiment and adopted for SysMO requirements.

# **********************************************************************************
# * myExperiment: lib/is_authorized.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# **********************************************************************************

module Authorization
  
  @@logger = RAILS_DEFAULT_LOGGER

  #the types of Assets supported by the Authorization module
  ASSET_TYPES=["Sop","Model","Asset","DataFile"]

  # 1) action_name - name of the action that is about to happen with the "thing"
  # 2) thing_type - class name of the thing that needs to be authorized;
  #                 use NIL as a value of this parameter if an instance of the object to be authorized is supplied as "thing";
  # 3) thing - this is supposed to be an instance of the thing to be authorized, but
  #            can also accept an ID (since we have the type, too - "thing_type")
  # 4) user - can be either user instance or the ID (NIL or 0 to indicate anonymous/not logged in user)
  #
  # Note: there is no method overloading in Ruby and it's a good idea to have a default "nil" value for "user";
  #       this leaves no other choice as to have (sometimes) redundant "thing_type" parameter.
  def Authorization.is_authorized?(action_name, thing_type, thing, user=nil)
    thing_instance = nil
    thing_asset = nil
    thing_id = nil
    user_instance = nil
    user_id = nil # if this value will not get updated by input parameters - user will be treated as anonymous
    user_person_id = nil

    # ***************************************
    #      Pre-checks on the Parameters
    # ***************************************

    # check first if the action that is being executed is known - not authorized otherwise
    action = categorize_action(action_name)
    return false unless action
    
    # if "thing" is unknown, or "thing" expresses ID of the object to be authorized, but "thing_type" is unknown - don't authorise the action
    # (this would allow, however, supplying no type, but giving the object instance as "thing" instead)
    return false if thing.blank? || (thing_type.blank? && thing.kind_of?(Numeric))
    
    
    # some value for "thing" supplied - assume that the object exists; check if it is an instance or the ID
    if thing.kind_of?(Numeric)
      # just an ID was provided - "thing_type" is assumed to have a type then
      thing_id = thing
    elsif thing.kind_of?(Asset)
      # thing_type/_id should be properties of the actual "thing", not it's asset
      thing_asset = thing
      thing_type = thing_asset.resource_type
      thing_id = thing_asset.resource_id
    elsif thing.class.name.ends_with?("::Version") && thing.respond_to?("parent") #its a ::Version, so test the parent
      thing_type = thing.parent.class.name unless thing_type.nil?
      return is_authorized?(action_name,thing_type,thing.parent,user)
    else
      # "thing" isn't an ID of the object; it's not a Asset, 
      # so it must be an instance of the object to be authorized -- this can be:
      # -- "resource" (SOP / spreadsheet / datafile / etc) : (will still have to "find" the Asset instance for this resource aftewards)
      thing_instance = thing
      thing_type = thing.class.name
      thing_id = thing.id
    end
    
    
    if user.kind_of?(User)
      user_instance = user
      user_id = user.id
      user_person_id = user.person_id
    elsif user == 0
      # "Authenticated System" sets current_user to 0 if not logged in (i.e. anonymous user)
      user_id = nil
    elsif user.nil? || user.kind_of?(Numeric)
      # anonymous user OR only id of the user, not an instance was provided;
      user_id = user
    end
    

    # ***************************************
    #      Actual Authorization Begins 
    # ***************************************

    # if (thing_type, ID) pair was supplied instead of a "thing" instance,
    # need to find the Asset for the object that needs to be authorized first;
    # (only do this for object types that are known to require authorization)
    #
    # this is required to get "policy_id" for policy-based authorized objects (like SOPs / spreadsheets / datafiles / assets)
    if (thing_asset.nil? && ASSET_TYPES.include?(thing_type))
      
      found_thing = find_thing(thing_type, thing_id)
      
      unless found_thing
        # search didn't yield any results - the "thing" wasn't found; can't authorize unknown objects
        @@logger.error("UNEXPECTED ERROR - Couldn't find object to be authorized:(#{thing_type}, #{thing_id}); action: #{action_name}; user: #{user_id}")
        return false
      else
        if ASSET_TYPES.include?(thing_type)
          # "assets" are only found for these types of object (and the assets themself),
          # for all the rest - use instances
          thing_asset = found_thing
        ## KEPT FOR FUTURE EXTENSION OPPORTUNITIES
        ## the following two lines of code might be useful in future, if any types
        ## of objects would require specific authorisation (i.e. not policy-based);
        ## "thing_instance" will then be used to invoke the .authorized? method 
        #else
        #  thing_instance = found_thing
        ## END
        end
      end
    end
    

    # initially not authorized, so if all tests fail -
    # safe result of being not authorized will get returned 
    is_authorized = false
    
    case thing_type
      when ASSET_TYPES.find{|el| el==thing_type}
        unless user_id.nil?
          # ******************* Checking Owner *******************
          # access is authorized and no further checks required in two cases:
          # ** user is the owner of the "thing"
          if is_owner?(user_id, thing_asset)
            unless action == "destroy"
              return true 
            else
              # check if nothing is linked to the "thing" and it wasn't used recently
              # TODO
              return true
            end
          end
          
          # ** user is admin of the policy associated with the "thing"
          #    (this means that the user might not have uploaded the "thing", but
          #     is the one managing the access permissions for it)
          #
          #    it's fine if policy will not be found at this step - default one will get
          #    used further when required
          policy_id = thing_asset.policy_id
          policy = get_policy(policy_id, thing_asset)
          return false unless policy # if policy wasn't found (and default one couldn't be applied) - error; not authorized
          if is_policy_admin?(policy, user_id)
            unless action == "destroy"
              return true 
            else
              # check if nothing is linked to the "thing" and it wasn't used recently
              # TODO
              return true
            end
          end
          
          
          # only owners / policy admins are allowed to perform actions categorized as "destroy";
          # hence "destroy" actions are not authorized below this point
          return false if action == "destroy"
          
          # sharing scope set to PRIVATE means that this asset isn't shared with anyone, and by
          # this point we already know that current user isn't the owner / policy admin of the asset
          return false if policy.sharing_scope == Policy::PRIVATE
          
          
          # for any further checks, person_id of the user that is being authorized is needed
          unless user_instance
            user_instance = get_user(user_id)
            
            # if the user instance wasn't found - user instance must have been deleted;
            # OR
            # if person_id is unknown for the found user instance (some kind of error must have happened - log this)
            # --> use public ("guest") settings in this case
            if user_instance.nil? || user_instance.person_id.nil? || user_instance.person_id == 0
              # make sure to log the error of 'person_id' being unknown or user_instance not found
              if user_instance.nil?
                @@logger.error("UNEXPECTED ERROR - Authorization module: Couldn't find user instance: user ID = #{user_id}")
              else
                @@logger.error("UNEXPECTED ERROR - Authorization module: User instance doesn't have a valid person_id: user ID = #{user_id}; person_id = #{user_instance.person_id}")
              end
              
              return authorized_by_policy?(policy, thing_asset, action, nil, nil)
            else
              user_person_id = user_instance.person_id
            end
          end
          
          # ******************* Checking Whitelist / Blacklist *******************
          # if using whitelist / blacklist allowed in policy, check if the user's person belongs to them;
          # blacklist denies any access, whitelist allows any access up to the level defined in FavouriteGroup
          # model (FavouriteGroup::WHITELIST_ACCESS_TYPE)
          #
          # this should only be carried out if the asset belongs to a User, not a Project or something else
          # (otherwise it doesn't make sense for those other types to have "favourite" groups, including
          #  whitelist / blacklist)
          if thing_asset.contributor_type == "User"
            if policy.use_blacklist
              return false if Authorization.is_person_in_blacklist?(user_person_id, thing_asset.contributor_id)
            end
            
            if policy.use_whitelist
              return true if Authorization.is_person_in_whitelist?(user_person_id, thing_asset.contributor_id) && Authorization.access_type_allows_action?(action, FavouriteGroup::WHITELIST_ACCESS_TYPE)
            end
          end
          
          
          # only do custom permission checking if the policy is known to have any  
          if policy.use_custom_sharing
            
            # ******************* Checking Individual Permissions *******************
            # user is not the owner/admin of the object; action is not of "destroy" class;
            # user's person is not found in whitelist / blacklist of the asset owner;
            #
            # next thing - obtain all the permissions that are relevant to the user
            # (start with individual user permissions; group permissions will only
            #  be considered if that is required further on)
            user_permissions = get_person_permissions(user_person_id, policy_id)
            
            
            # individual user (person) permissions override any other settings;
            # if several of these are found (which shouldn't be the case),
            # all are considered, but the one with "highest" access right is
            # used to make final decision -- that is if at least one of the
            # user permissions allows to make the action, it will be allowed;
            # likewise, if none of the permissions allow the action it will
            # not be allowed
            unless user_permissions.empty?
              authorized_by_user_permissions = false
              user_permissions.each do |p|
                authorized_by_user_permissions = true if access_type_allows_action?(action, p.access_type)
              end
              return authorized_by_user_permissions
            end
            
            
            # ******************* Checking "Favourite" Groups *******************
            access_rights_in_favourite_groups = get_person_access_rights_from_favourite_group_permissions(user_person_id, policy_id)
            unless access_rights_in_favourite_groups.empty?
              authorized = false
              access_rights_in_favourite_groups.each do |p|
                authorized = true if access_type_allows_action?(action, p.access_type)
              end
              return authorized
            end
          end
          
          
          # ******************* Checking General Policy Settings *******************
          # no user permissions found, need to check what is allowed by policy
          # (if no policy was found, default policy is in use instead)
          authorized_by_policy = false
          authorized_by_policy = authorized_by_policy?(policy, thing_asset, action, user_id, user_person_id)
          return true if authorized_by_policy
          

          # only do custom permission checking if the policy is known to have any  
          if policy.use_custom_sharing
            # ******************* Checking Group Permissions *******************
            # not authorized by policy, check the group permissions -- the ones
            # attached to "thing's" policy and belonging to the groups, where
            # "user" is a member of - i.e. all Projects, Institutions, WorkGroups
            #
            # these cannot limit what is allowed by policy settings, only give more access rights 
            authorized_by_group_permissions = false
            group_permissions = get_group_permissions(policy_id)
            
            unless group_permissions.empty?
              group_permissions.each do |p|
                # check if this permission is applicable to the "user" - i.e. to the user's person
                if access_type_allows_action?(action, p.access_type) && is_member?(user_person_id, p.contributor_type, p.contributor_id)
                  authorized_by_group_permissions = true
                  break
                end
              end
              return authorized_by_group_permissions if authorized_by_group_permissions
            end
          end
          
          # user permissions, policy settings and group permissions didn't give the
          # positive result - decline the action request
          return false
        
        else
          # this is for cases where trying to authorize anonymous users;
          # the only possible check - on public policy settings:
          policy_id = thing_asset.policy_id
          policy = get_policy(policy_id, thing_asset)
          return false unless policy # if policy wasn't found (and default one couldn't be applied) - error; not authorized
          
          return authorized_by_policy?(policy, thing_asset, action, nil, nil)
        end
        
      ## THE FOLLOWING FRAGMENT IS LEFT HERE TO SHOW HOW "thing_instance" MAY BE USED
      ## this could be useful when some specific object types will not require policy-
      ## based authorization; then the only thing which is needed - is to call the 
      ## .authorized?(), or similar, method on the instance of the object ot be authorized
      #when "Experiment", "Job", "TavernaEnactor", "Runner"
      #  # user instance is absolutely required for this - so find it, if not yet available
      #  unless user_instance
      #    user_instance = get_user(user_id)
      #  end
      #  
      #  # "thing_instance" was already found previously;
      #  # neither of these "thing" types uses policy-based authorization, hence use
      #  # the existing <thing>.authorized?() method
      #  #
      #  # "action_name" used to work with original action name, rather than classification made inside the module
      #  is_authorized = thing_instance.authorized?(action_name, user)
      ## END
      else
        # don't recognise the kind of "thing" that is being authorized, so
        # we don't specifically know that it needs to be blocked;
        # therefore, allow any actions on it
        is_authorized = true
    end
    
    return is_authorized
    
  end


  # convenience method which iterates through an array of items performing authorization on
  # each for given user instance and action name;
  # - keep_nil_records - will keep placeholders for not authorized items; can be useful, for example, for attributions
  #                      to show that entry exists, but gives no information on what is hiding behind it
  def Authorization.authorize_collection(action_name, item_array, user, keep_nil_records=false)
    # check first if the action that is being executed is known - not authorized otherwise
    action = categorize_action(action_name)
    return [] unless action
    
    # if there are no items or the array is nil, return empty array
    return [] if item_array.blank?
    
    # otherwise perform authorization for every item
    authorized_items = item_array.collect do |item|
      Authorization.is_authorized?(action, nil, item, user) ? item : nil
    end
    
    unless keep_nil_records
      # not authorized items have been turned into NILs - remove these
      authorized_items.delete(nil)
    end
    
    return authorized_items
  end
  

  private

  def Authorization.categorize_action(action_name)
    case action_name
      when 'show', 'index', 'view', 'search', 'favourite', 'favourite_delete', 'comment', 'comment_delete', 'comments', 'comments_timeline', 'rate', 'tag',  'items', 'statistics', 'tag_suggestions'
        action = 'view'
      when 'edit', 'new', 'create', 'update', 'new_version', 'create_version', 'destroy_version', 'edit_version', 'update_version', 'new_item', 'create_item', 'edit_item', 'update_item', 'quick_add', 'resolve_link'
        action = 'edit'
      when 'download', 'named_download', 'launch', 'submit_job'
        action = 'download'
      when 'destroy', 'destroy_item', 'manage'
        action = 'destroy'
      when 'execute'
        # action is available only(?) for runners at the moment;
        # possibly, "launch" action for workflows should be moved into this category, too
        action = 'execute'
      else
        # unknown action
        action = nil
    end
    
    return action
  end

  # check if the DB holds entry for the "thing" to be authorized 
  def Authorization.find_thing(thing_type, thing_id)
    found_instance = nil
    
    begin
      case thing_type
        when ASSET_TYPES.find{|el| el!="Asset" && el==thing_type} #, "Datafile", "Spreadsheet", etc
          # "find_by_sql" works faster itself PLUS only a subset of all fields is selected;
          # this is the most frequent query to be executed, hence needs to be optimised
          found_instance = Asset.find_by_sql "SELECT id, contributor_id, contributor_type, policy_id FROM assets WHERE resource_id=#{thing_id} AND resource_type='#{thing_type}'"
          found_instance = (found_instance.empty? ? nil : found_instance[0]) # if nothing was found - nil; otherwise - first match
        when "Asset"
          # fairly possible that it's going to be an asset itself, not a resource
          found_instance = Asset.find(thing_id, :select => "id, contributor_id, contributor_type, policy_id")
        else
          # unknown type
          return nil
      end
    rescue ActiveRecord::RecordNotFound
      # do nothing; makes sure that app won't crash when the required object is not found;
      # the method will return "nil" anyway, so no need to take any further actions here
    end
    
    return found_instance
  end


  # checks if "user" is owner of the "thing"
  def Authorization.is_owner?(user_id, thing_asset)
    is_authorized = false

    # if owner of the "thing" is the "user" then the "user" is authorized
    if thing_asset.contributor_type == 'User' && thing_asset.contributor_id == user_id
      is_authorized = true
    ## AN OWNER COULD BE ANOTHER TYPE - EXPAND THE OPTIONS BELOW THIS LINE
    #elsif thing_asset.contributor_type == 'Network'
    #  is_authorized = is_network_admin?(user_id, thing_asset.contributor_id)
    ## END
    end

    return is_authorized
  end
  
  
  # checks if "user" is admin of the policy associated with the "thing"
  def Authorization.is_policy_admin?(policy, user_id)
    # if anonymous user or no policy provided - definitely not policy admin
    return false unless (policy && user_id)
    
    return(policy.contributor_type == 'User' && policy.contributor_id == user_id)
  end
  
  
  # checks if a person belongs to a blacklist of a particular user
  def Authorization.is_person_in_blacklist?(person_id, blacklist_owner_user_id)
    access_rights = Authorization.get_person_access_rights_in_favourite_group(person_id, [blacklist_owner_user_id, FavouriteGroup::BLACKLIST_NAME])
    
    # found value should be an expected one
    return (!access_rights.nil? && access_rights == FavouriteGroup::BLACKLIST_ACCESS_TYPE)
  end
  
  
  # checks if a person belongs to a whitelist of a particular user
  def Authorization.is_person_in_whitelist?(person_id, whitelist_owner_user_id)
    access_rights = Authorization.get_person_access_rights_in_favourite_group(person_id, [whitelist_owner_user_id, FavouriteGroup::WHITELIST_NAME])
    
    # found value should be an expected one 
    return (!access_rights.nil? && access_rights == FavouriteGroup::WHITELIST_ACCESS_TYPE)
  end
  
  
  # checks if person with ID(person_id) is a member of the group having ID(group_id) and TYPE(group_type);
  # if "group_type" and "group_id" are supplied as NIL, the method will check if the Person with ID(person_id)
  # belongs to any work groups / projects / institutions
  def Authorization.is_member?(person_id, group_type, group_id)
    if group_type == "FavouriteGroup"
      member = FavouriteGroup.find_by_sql "SELECT id FROM favourite_group_memberships WHERE person_id=#{person_id} and favourite_group_id=#{group_id}"
    elsif group_type == "WorkGroup"
      member = GroupMembership.find_by_sql "SELECT id FROM group_memberships WHERE person_id=#{person_id} AND work_group_id=#{group_id}"
    elsif group_type == "Project" || group_type == "Institution"
      query =  "SELECT g_memb.id FROM group_memberships g_memb JOIN work_groups wg ON g_memb.work_group_id = wg.id "
      query += "WHERE g_memb.person_id=#{person_id} AND wg.#{group_type.downcase}_id=#{group_id}"
      member = GroupMembership.find_by_sql(query)
    elsif group_type.nil? && group_id.nil?
      member = GroupMembership.find_by_sql "SELECT id FROM group_memberships WHERE person_id=#{person_id}"
    end
    
    return(!member.blank?)
  end
  

  # gets the user object from the user_id;
  # used by is_authorized when calling model.authorized? method for classes that don't use policy-based authorization;
  # also used when person_id of the user is required
  def Authorization.get_user(user_id)
    return nil if user_id == 0
    
    begin
      user = User.find(:first, :conditions => ["id = ?", user_id], :select => "id, person_id")
      return user
    rescue ActiveRecord::RecordNotFound
      # user not found, "nil" for anonymous user will be returned
      return nil
    end
  end
  
  
  # query database for relevant fields in policies table
  #
  # Parameters:
  # 1) policy_id - ID of the policy to find in the DB;
  # 2) thing_asset - Asset object for the "thing" that is being authorized;
  def Authorization.get_policy(policy_id, thing_asset)
    unless policy_id.blank?
      select_string = 'contributor_id, contributor_type, sharing_scope, access_type, use_custom_sharing, use_whitelist, use_blacklist'
      policy_array = Policy.find_by_sql "SELECT #{select_string} FROM policies WHERE policies.id=#{policy_id}"
      
      # if nothing's found, use the default policy
      policy = (policy_array.blank? ? get_default_policy(thing_asset) : policy_array[0])
    else
      # if the "policy_id" turns out unknown, use default policy
      policy = get_default_policy(thing_asset)
    end
    
    return policy
  end
  
  
  # if a policy instance not found to be associated with the Asset of a "thing", use a default one
  def Authorization.get_default_policy(thing_asset)
    # an unlikely event that asset doesn't have a policy - need to use
    # default one; "owner" of the asset will be treated as policy admin
    #
    # the following is slow, but given the very rare execution can be kept
    begin
      # thing_asset is Asset, so thing_asset.contributor is the original uploader == owner of the item
      contributor = eval("#{thing_asset.contributor_type}.find(#{thing_asset.contributor_id})")
      policy = Policy.default(contributor, thing_asset.project)
      return policy
    rescue ActiveRecord::RecordNotFound => e
      # original contributor not found, but the Asset entry still exists -
      # this is an error in associations then, because all dependent items
      # should have been deleted along with the contributor entry; log the error
      @@logger.error("UNEXPECTED ERROR - Contributor object missing for an existing asset: (#{thing_asset.class.name}, #{thing_asset.id})")
      @@logger.error("EXCEPTION:" + e)
      return nil
    end
  end
  
  
  # get all user permissions related to policy for the "thing" for "person"
  # (Persons are used instead of users to allow sharing with people, who don't have
  #  a registered user account just yet)
  def Authorization.get_person_permissions(person_id, policy_id)
    unless person_id.blank? || policy_id.blank?
      Permission.find_by_sql "SELECT access_type FROM permissions WHERE policy_id=#{policy_id} AND contributor_type='Person' AND contributor_id=#{person_id}"
    else
      # an empty array to be returned has the same effect as if no permissions were found anyway
      return []
    end
  end
  
  
  # Finds access rights ("access_type") of a person within a particular "favoutite_group";
  #
  # Returns: access type code (defined in Policy model) or NIL if a person is not in that favourite group.
  # Parameters:
  # 1) person_id
  # 2) favourite_group - an ID of the favourite group to check OR 
  #                      an array with 2 elements: [<id_of_the_user_who_is_owner_of_that_group>, <favourite_group_name>]
  def Authorization.get_person_access_rights_in_favourite_group(person_id, favourite_group)
    # initialize variable to hold return value
    found = []
    
    if favourite_group.kind_of?(Numeric)
      # if an ID of the favourite group is supplied, can use a direct query 
      found = FavouriteGroupMembership.find_by_sql "SELECT access_type FROM favourite_group_memberships WHERE person_id=#{person_id} AND favourite_group_id=#{favourite_group}"
    elsif favourite_group.kind_of?(Array) && favourite_group.length == 2 && favourite_group[0].kind_of?(Numeric) && favourite_group[1].kind_of?(String)
      # "favourite_group" doesn't contain an integer ID of the group; parameter type check for second option passed;
      # so "favourite_group" should be an array with an ID of the owner (user) of that group and a string containing its name;
      #
      # names of favourite groups are *unique* so can use a join and one result will always be yielded
      found = FavouriteGroupMembership.find_by_sql "SELECT access_type FROM favourite_group_memberships g_memb JOIN favourite_groups g ON g.id = g_memb.favourite_group_id WHERE g_memb.person_id=#{person_id} AND g.user_id=#{favourite_group[0]} AND g.name='#{favourite_group[1]}'"
    end
    
    # access_type code returned; if nothing found (or nothing processed because of illegal parameter values), return NIL 
    # (NIL is illegal value for "access_type", hence can be used to return a 'not found' result)
    return (found.length == 0 ? nil : found[0].access_type)
  end
  
  
  # get all permissions that the Person with ID(person_id) has from the asset owner's "favourite" groups,
  # with which the "thing" is shared by the permissions associated with the "thing's" policy
  def Authorization.get_person_access_rights_from_favourite_group_permissions(person_id, policy_id)
    unless policy_id.blank?
      query =  "SELECT g_memb.access_type FROM favourite_group_memberships g_memb JOIN permissions p ON g_memb.favourite_group_id = p.contributor_id "
      query += "WHERE p.policy_id=#{policy_id} AND p.contributor_type='FavouriteGroup' AND g_memb.person_id=#{person_id}"
      FavouriteGroupMembership.find_by_sql(query)
    else
      # an empty array to be returned has the same effect as if no permissions were found anyway
      return []
    end
  end
  
  
  # get all group permissions related to policy for the "thing";
  # group types that are selected: Institutions, Projects, WorkGroups (projects @ institutions);
  # FavouriteGroups not considered here, because they were analysed previously
  def Authorization.get_group_permissions(policy_id)
    unless policy_id.blank?
      select_string = 'contributor_type, contributor_id, access_type'
      Permission.find_by_sql "SELECT #{select_string} FROM permissions WHERE policy_id=#{policy_id} AND contributor_type IN ('Project', 'Institution', 'WorkGroup')"
    else
      # an empty array to be returned has the same effect as if no permissions were found anyway
      return []
    end
  end
  
  
  # checks whether "user" is authorized for "action" on "thing"
  # (this mainly tests different kinds of 'public' / 'limited public' permissions,
  #  because individual permissions are defined not in the Policy, but in Permissions) 
  def Authorization.authorized_by_policy?(policy, thing_asset, action, user_id, user_person_id)
    is_authorized = false
    
    # NB! currently SysMO won't support objects owned by entities other than users
    # (especially, policy checks are not agreed for these cases - however, owner tests and
    #  permission tests are possible and will be carried out)
    unless thing_asset.contributor_type == "User"
      return false
    end
    
    ####################################################################################
    #
    # For details on sharing_scope / access_type, see comments in the Policy model
    #
    ####################################################################################
    share_mode = policy.sharing_scope
    access_mode = policy.access_type

    # check if shared with public AND access mode in the policy allows the required action to be performed;
    # it only makes sense to check if the policy covers current user if the action *could*
    # potentially be allowed at all 
    if share_mode >= Policy::ALL_SYSMO_USERS && access_type_allows_action?(action, access_mode)
      case share_mode
        when Policy::EVERYONE
          is_authorized = true
        when Policy::ALL_REGISTERED_USERS
          # all logged in users are authorized
          is_authorized = (!user_id.nil? && user_id != 0)
        when Policy::ALL_SYSMO_USERS
          # current user should be logged in AND be associated with some projects
          is_authorized = (!user_id.nil? && user_id != 0) && is_member?(user_person_id, nil, nil)
        #else
          # do nothing, but other modes do not authorize any public users 
      end
    end

    return is_authorized
  end
  
  
  # checks if the "access_type" permits an action of a certain type (based on cascading permissions)
  def Authorization.access_type_allows_action?(action, access_type)
    # check that a permission instance was supplied
    return false if (action.blank? || access_type.blank?)
    
    case action
      when "view"
        return access_type >= Policy::VIEWING
      when "download"
        return access_type >= Policy::DOWNLOADING
      when "edit"
        return access_type >= Policy::EDITING
      else
        # any other type of action is not allowed by permissions
        return false
    end
  end


  
end
