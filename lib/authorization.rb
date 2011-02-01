# SysMO: lib/authorization.rb
# Code taken from myExperiment and adopted for SysMO requirements.
# Greatly simplified 22/7/2010
# **********************************************************************************
# * myExperiment: lib/is_authorized.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# **********************************************************************************

module Authorization
  
  @@logger = RAILS_DEFAULT_LOGGER
  

  
  # 1) action_name - name of the action that is about to happen with the "thing"
  # 2) thing_type - class name of the thing that needs to be authorized;
  #                 use NIL as a value of this parameter if an instance of the object to be authorized is supplied as "thing";
  # 3) thing - instance of resource to be authorized
  # 4) user - instance of user
  def self.is_authorized?(action_name, thing_type, thing, user=nil)    
    # ***************************************
    #      Pre-checks on the Parameters
    # ***************************************

    #Don't try and authorize things that don't have policies!
    return true unless thing.authorization_supported?
    
    # check first if the action that is being executed is know
    # - it should be, if not there's a bug in the code
    action = categorize_action(action_name)
    
    # ***************************************
    #      Actual Authorization Begins 
    # ***************************************
    
    # initially not authorized, so if all tests fail -
    # safe result of being not authorized will get returned 
    is_authorized = false
    
    policy = thing.policy
    
    # == BASIC POLICY
    # 1. Check the user's "scope" level, to match the sharing scopes defined in policy.
    # 2. If they're in "scope", check the action they're trying to perform is allowed by the access_type    
    scope = nil
    if user.nil?
      scope = Policy::EVERYONE
    else
      if thing.contributor == user #Warning to future refactorers, this would pass in the case that
                                   #  the user was nil (not logged in) and the contributor was also nil (jerm resource)
                                   #  IF we didn't already check for a nil user above.
        scope = Policy::PRIVATE
        return true #contributor is always authorized 
        # have to do this because of inconsistancies with access_type that mess up later on
        # (4 = can manage, 0 = can manage... if contributor) ???
      else
        if user.person && user.person.projects.empty?
          scope = Policy::ALL_REGISTERED_USERS
        else
          scope = Policy::ALL_SYSMO_USERS
        end
      end
    end
    
    # Check the user is "in scope" and also is performing an action allowed under the given access type
    is_authorized = is_authorized || (scope <= policy.sharing_scope && 
                                      access_type_allows_action?(action, policy.access_type))
    # == END BASIC POLICY
    
    if policy.use_custom_sharing && user
      # == CUSTOM PERMISSIONS
      # 1. Check if there is a specific permission relating to the user
      # 2. Check if there is a permission for a FavouriteGroup they're in
      # 3. Check if there is a permission for their project
      # 4. Check the action is allowed by the access_type of the permission
      permissions = []
      
      # Person permissions
      permissions = policy.permissions.select {|p| p.contributor == user.person}
      
      # FavouriteGroup permissions
      if permissions.empty?
        favourite_group_ids = policy.permissions.select {|p| p.contributor_type == "FavouriteGroup"}.collect {|p| p.contributor_id}
        #Use favourite_group_membership in place of permission, because the access_type is stored in it for some reason.
        # Duck typing will save us.
        permissions = user.person.favourite_group_memberships.select {|x| favourite_group_ids.include?(x.favourite_group_id)}
      end

      # WorkGroup permissions
      if permissions.empty?
        work_group_ids = user.person.work_group_ids
        permissions = policy.permissions.select {|p| p.contributor_type == "WorkGroup" && work_group_ids.include?(p.contributor_id)}
      end
     
      # Project permissions
      if permissions.empty?
        project_ids = user.person.projects.collect {|p| p.id}
        permissions = policy.permissions.select {|p| p.contributor_type == "Project" && project_ids.include?(p.contributor_id)}
      end
      
      # Institution permissions
      if permissions.empty?
        institution_ids = user.person.institutions.collect {|i| i.id}
        permissions = policy.permissions.select {|p| p.contributor_type == "Institution" && institution_ids.include?(p.contributor_id)}
      end
      
      unless permissions.empty?
        #Get max access level from permissions (in the event there is more than 1... there shouldn't be)
        max_access_type = permissions.sort_by{|p| p.access_type}.last.access_type
        #override current authorization status
        is_authorized = access_type_allows_action?(action, max_access_type)
      end
      
      # == END CUSTOM PERMISSIONS
    end
    
    # == BLACK/WHITE LISTS
    # 1. Check if they're in the whitelist
    # 2. Check if they're not in the blacklist (overrules whitelist)
    if thing.contributor
      # == WHITE LIST
      if policy.use_whitelist && thing.contributor.get_whitelist
        is_authorized = true if is_person_in_whitelist?(user.person, thing.contributor) && access_type_allows_action?(action, FavouriteGroup::WHITELIST_ACCESS_TYPE)
      end
      # == END WHITE LIST
      # == BLACK LIST
      if policy.use_blacklist && thing.contributor.get_blacklist
        is_authorized = false if is_person_in_blacklist?(user.person, thing.contributor)
      end
      # == END BLACK LIST
    end
    # == END BLACK/WHITE LISTS
    
    return is_authorized    
  end


  # convenience method which iterates through an array of items performing authorization on
  # each for given user instance and action name;
  # - keep_nil_records - will keep placeholders for not authorized items; can be useful, for example, for attributions
  #                      to show that entry exists, but gives no information on what is hiding behind it
  def self.authorize_collection(action_name, item_array, user, keep_nil_records=false)
    # otherwise perform authorization for every item
    authorized_items = item_array.collect do |item|
      Authorization.is_authorized?(action_name, nil, item, user) ? item : nil
    end
    
    # not authorized items have been turned into NILs - remove these
    unless keep_nil_records
      authorized_items = authorized_items.compact
    end
    
    return authorized_items
  end
  
  #Delete this after fixing refs
  def self.is_member?(person_id, what, whatever)
    !Person.find_by_id(person_id).projects.empty?
  end
  
  private
  
  def self.categorize_action(action_name)
    case action_name
      when 'show', 'index', 'view', 'search', 'favourite', 'favourite_delete',
           'comment', 'comment_delete', 'comments', 'comments_timeline', 'rate',
           'tag',  'items', 'statistics', 'tag_suggestions','preview'
        action = 'view'
        
      when 'download', 'named_download', 'launch', 'submit_job', 'data', 'execute'
        action = 'download'
        
      when 'edit', 'new', 'create', 'update', 'new_version', 'create_version',
           'destroy_version', 'edit_version', 'update_version', 'new_item',
           'create_item', 'edit_item', 'update_item', 'quick_add', 'resolve_link'
        action = 'edit'
        
      when 'destroy', 'destroy_item', 'manage'
        action = 'destroy'

      else
        # unknown action
        action = nil
    end
    
    return action
  end
  
  # checks if a person belongs to a blacklist of a particular user
  def self.is_person_in_blacklist?(person, blacklist_owner)
    return blacklist_owner.get_blacklist.people.include?(person)
  end
  
  # checks if a person belongs to a whitelist of a particular user
  def self.is_person_in_whitelist?(person, whitelist_owner)
    return whitelist_owner.get_whitelist.people.include?(person)
  end
  
  # checks if the "access_type" permits an action of a certain type (based on cascading permissions)
  def self.access_type_allows_action?(action, access_type)
    case action
      when "view"
        return access_type >= Policy::VISIBLE
      when "download"
        return access_type >= Policy::ACCESSIBLE
      when "edit"
        return access_type >= Policy::EDITING
      when "destroy"
        return access_type >= Policy::MANAGING
    else
      # any other type of action is not allowed by permissions
      return false
    end
  end
end