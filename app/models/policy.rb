class Policy < ActiveRecord::Base
  
  has_many :permissions,
           :dependent => :destroy,
           :order => "created_at ASC",
           :autosave => true,
           :after_add => proc {|policy, perm| perm.policy = policy}

  #basically the same as validates_numericality_of :sharing_scope, :access_type
  #but with a more generic error message because our users don't know what
  #sharing_scope and access_type are.
  validates_each(:sharing_scope, :access_type) do |record, attr, value|
    raw_value = record.send("#{attr}_before_type_cast") || value
    begin
      Kernel.Float(raw_value)
    rescue ArgumentError, TypeError
      record.errors[:base] << "Sharing policy is invalid" unless value.is_a? Integer
    end
  end
  
  alias_attribute :title, :name

  after_commit :queue_update_auth_table
  before_save :update_timestamp_if_permissions_change

  def update_timestamp_if_permissions_change
    update_timestamp if changed_for_autosave?
  end

  def queue_update_auth_table
    unless (previous_changes.keys - ["updated_at"]).empty?
      AuthLookupUpdateJob.new.add_items_to_queue(assets) unless assets.empty?
    end
  end

  def assets
    Seek::Util.authorized_types.collect do |type|
      type.where(:policy_id=>id)
    end.flatten.uniq
  end
  
  
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
  ALL_USERS = 2
  EVERYONE = 4
  
  # access_type
  DETERMINED_BY_GROUP = -1  # used for whitelist/blacklist (meaning that it doesn't matter what value this field has)
  NO_ACCESS = 0             # i.e. only for anyone; only owner has access
  VISIBLE = 1               # visible only
  ACCESSIBLE = 2            # accessible and visible
  EDITING = 3               # accessible, visible and editing
  MANAGING = 4              # any actions that owner of the asset can perform (including "destroy"ing)
  PUBLISHING = 5            # publish the item
    
  # "true" value for flag-type fields
  TRUE_VALUE = 1
  FALSE_VALUE = 0
  # *****************************************************************************
  
  #makes a copy of the policy, and its associated permissions.
  def deep_copy
    copy=self.dup
    copied_permissions = self.permissions.collect {|p| p.dup}
    copied_permissions.each {|p| copy.permissions << p}
    copy
  end

  #checks that there are permissions for the provided contributor, for the access_type (or higher)
  def permission_granted?(contributor,access_type)
    permissions.detect{|p| p.contributor==contributor && p.access_type >= access_type}
  end

  def self.new_for_upload_tool(resource, recipient)
    policy = resource.build_policy(:name               => 'auto',
                                    :sharing_scope      => Policy::PRIVATE,
                                    :access_type        => Policy::NO_ACCESS)
    policy.permissions.build :contributor_type => "Person", :contributor_id => recipient, :access_type => Policy::ACCESSIBLE
    return policy
  end

  def self.new_from_email(resource, recipients, accessors)
    policy = resource.build_policy(:name               => 'auto',
                                   :sharing_scope      => Policy::PRIVATE,
                                   :access_type        => Policy::NO_ACCESS)
    recipients.each do |id|
      policy.permissions.build :contributor_type => "Person", :contributor_id => id, :access_type => Policy::EDITING
    end if recipients

    accessors.each do |id|
      policy.permissions.build :contributor_type => "Person", :contributor_id => id, :access_type => Policy::ACCESSIBLE
    end if accessors

    return policy
  end


  def set_attributes_with_sharing sharing, projects
    # if no data about sharing is given, it should be some user (not the owner!)
    # who is editing the asset - no need to do anything with policy / permissions: return success
    self.tap do |policy|
      if sharing

        # obtain parameters from sharing hash
        policy.sharing_scope = sharing[:sharing_scope]

        policy.access_type = sharing["access_type_#{sharing_scope}"].blank? ? 0 : sharing["access_type_#{sharing_scope}"]

        # NOW PROCESS THE PERMISSIONS

        # read the permission data from sharing
        unless sharing[:permissions].blank? or sharing[:permissions][:contributor_types].blank?
          contributor_types = ActiveSupport::JSON.decode(sharing[:permissions][:contributor_types]) || []
          new_permission_data = ActiveSupport::JSON.decode(sharing[:permissions][:values]) || {}
        else
          contributor_types = []
          new_permission_data = {}
        end

        #if share with your project is chosen

        if (sharing[:sharing_scope].to_i == Policy::ALL_USERS) and !projects.map(&:id).compact.blank?
          #add Project to contributor_type
          contributor_types << "Project" if !contributor_types.include? "Project"
          #add one hash {project.id => {"access_type" => sharing[:your_proj_access_type].to_i}} to new_permission_data
          new_permission_data["Project"] = {} unless new_permission_data["Project"]
          projects.each {|project| new_permission_data["Project"][project.id.to_s] = {"access_type" => sharing[:your_proj_access_type].to_i}}
        end

        # --- Synchronise All Permissions for the Policy ---
        # first delete or update any old memberships
        policy.permissions.each do |p|
          if permission_access = (new_permission_data[p.contributor_type.to_s].try :delete, p.contributor_id.to_s)
            p.access_type = permission_access["access_type"]
          else
            p.mark_for_destruction
          end
        end

        # now add any remaining new memberships
        contributor_types.try :each do |contributor_type|
          new_permission_data[contributor_type.to_s].try :each do |p|
            if policy.new_record? or !Permission.where(:contributor_type => contributor_type, :contributor_id => p[0], :policy_id => policy.id).first
              p = policy.permissions.build :contributor_type => contributor_type, :contributor_id => p[0], :access_type => p[1]["access_type"]
            end
          end
        end

      end
    end
  end
    
  # returns a default policy for a project
  # (all the related permissions will still be linked to the returned policy)
  def self.project_default(project)
    # if the default project policy isn't set, NIL will be returned - and the caller
    # has to perform further actions in such case
    return project.default_policy
  end
  
  def self.private_policy
    Policy.new(:name => "default private",
               :sharing_scope => PRIVATE,
               :access_type => NO_ACCESS,
               :use_whitelist => false,
               :use_blacklist => false)
  end

  def self.registered_users_accessible_policy
    Policy.new(:name => "default accessible",
               :sharing_scope => ALL_USERS,
               :access_type => ACCESSIBLE,
               :use_whitelist => false,
               :use_blacklist => false)
  end

  def self.public_policy
      Policy.new(:name => "default public",
                          :sharing_scope => EVERYONE,
                          :access_type => ACCESSIBLE
      )
  end

  def self.sysmo_and_projects_policy projects=[]
      policy = Policy.new(:name => "default sysmo and projects policy",
                          :sharing_scope => ALL_USERS,
                          :access_type => VISIBLE
      )
      projects.each do |project|
        policy.permissions << Permission.new(:contributor => project, :access_type => ACCESSIBLE)
      end
      return policy
  end

  #The default policy to use when creating authorized items if no other policy is specified
  def self.default resource=nil
    #FIXME: - would like to revisit this, remove is_virtualiver, and make the default policy itself a configuration
    unless Seek::Config.is_virtualliver
      private_policy
    else
      Policy.new(:name => "default accessible", :use_whitelist => false, :use_blacklist => false)
    end
  end
   
  # translates access type codes into human-readable form  
  def self.get_access_type_wording(access_type, downloadable=false)
    case access_type
      when Policy::DETERMINED_BY_GROUP
        return I18n.t('access.determined_by_group')
      when Policy::NO_ACCESS
        return I18n.t("access.no_access")
      when Policy::VISIBLE
        return downloadable ? I18n.t('access.visible_downloadable') : I18n.t('access.visible')
      when Policy::ACCESSIBLE
        return downloadable ? I18n.t('access.accessible_downloadable') : I18n.t('access.accessible')
      when Policy::EDITING
        return downloadable ? I18n.t('access.editing_downloadable') : I18n.t('access.editing')
      when Policy::MANAGING
        return I18n.t('access.managing')
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

  def private?
    sharing_scope == Policy::PRIVATE && permissions.empty?
  end

  def public?
    sharing_scope == Policy::EVERYONE
  end

#return the hash: key is access_type, value is the array of people
  def summarize_permissions creators=[User.current_user.try(:person)], asset_housekeepers = [], contributor=User.current_user.try(:person)
        #build the hash containing contributor_type as key and the people in these groups as value,exception:'Public' holds the access_type as the value
        people_in_group = {'Person' => [], 'FavouriteGroup' => [], 'WorkGroup' => [], 'Project' => [], 'Institution' => [], 'WhiteList' => [], 'BlackList' => [],'Network' => [], 'Public' => 0}
        #the result return: a hash contain the access_type as key, and array of people as value
        grouped_people_by_access_type = {}

        policy_to_people_group people_in_group, contributor

        permissions_to_people_group permissions, people_in_group

        #Now make the people in group unique by choosing the highest access_type
        people_in_group['FavouriteGroup']  = remove_duplicate(people_in_group['FavouriteGroup'])
        people_in_group['WorkGroup']  = remove_duplicate(people_in_group['WorkGroup'])
        people_in_group['Project']  = remove_duplicate(people_in_group['Project'])
        people_in_group['Institution']  = remove_duplicate(people_in_group['Institution'])

        #Now process precedence with the order [network, institution, project, wg, fg, person]
        filtered_people = people_in_group['Network']
        filtered_people = precedence(filtered_people, people_in_group['Institution'])
        filtered_people = precedence(filtered_people, people_in_group['Project'])
        filtered_people = precedence(filtered_people, people_in_group['WorkGroup'])
        filtered_people = precedence(filtered_people, people_in_group['FavouriteGroup'])
        filtered_people = precedence(filtered_people, people_in_group['Person'])

        #add people in white list
        filtered_people = add_people_in_whitelist(filtered_people, people_in_group['WhiteList'])
        #add people in blacklist
        filtered_people = precedence(filtered_people, people_in_group['BlackList'])

        #add creators and assign them the Policy::EDITING right
        creator_array = creators.collect{|c| [c.id, "#{c.name}", Policy::EDITING] unless c.blank?}
        filtered_people = add_people_in_whitelist(filtered_people, creator_array)

        #add contributor
        filtered_people = add_people_in_whitelist(filtered_people, [[contributor.id, "#{contributor.name}", Policy::MANAGING]]) unless contributor.blank?

        #sort people by name
        filtered_people = filtered_people.sort{|a,b| a[1] <=> b[1]}

        #group people by access_type
        grouped_people_by_access_type.merge!(filtered_people.group_by{|person| person[2]})

        asset_housekeeper_array = asset_housekeepers.collect { |am| [am.id, "#{am.name}", Policy::MANAGING] unless am.blank? }
        if grouped_people_by_access_type[Policy::MANAGING].blank?
          grouped_people_by_access_type[Policy::MANAGING] = asset_housekeeper_array
        else
          grouped_people_by_access_type[Policy::MANAGING] |= asset_housekeeper_array
        end

        #concat the roles to a person name
        concat_roles_to_name grouped_people_by_access_type, creators, asset_housekeepers

        #use Policy::DETERMINED_BY_GROUP to store public group if access_type for public > 0
        grouped_people_by_access_type[Policy::DETERMINED_BY_GROUP] = people_in_group['Public'] if people_in_group['Public'] > 0

        #sort by key of the hash
        grouped_people_by_access_type = Hash[grouped_people_by_access_type.sort]

        return grouped_people_by_access_type
  end

  def policy_to_people_group people_in_group, contributor=User.current_user.person
      if sharing_scope == Policy::ALL_USERS
         people_in_network = get_people_in_network access_type
         people_in_group['Network'] |= people_in_network unless people_in_network.blank?
      elsif sharing_scope == Policy::EVERYONE
        people_in_group['Public'] = access_type
      end
      #if blacklist/whitelist is used
      if use_whitelist
        people_in_whitelist = get_people_in_FG(contributor, nil, true, nil)
        people_in_group['WhiteList'] |= people_in_whitelist unless people_in_whitelist.blank?
      end
      #if blacklist/whitelist is used
      if use_blacklist
        people_in_blacklist = get_people_in_FG(contributor, nil, nil, true)
        people_in_group['BlackList'] |= people_in_blacklist unless people_in_blacklist.blank?
      end
      people_in_group
  end

  def permissions_to_people_group permissions, people_in_group
      permissions.each do |permission|
        contributor_id = permission.contributor_id
        access_type = permission.access_type
        case permission.contributor_type
           when 'Person'
               person = get_person contributor_id, access_type
               people_in_group['Person'] << person unless person.blank?
           when 'FavouriteGroup'
               people_in_FG = get_people_in_FG nil, contributor_id
               people_in_group['FavouriteGroup'] |= people_in_FG unless people_in_FG.blank?
           when 'WorkGroup'
               people_in_WG = get_people_in_WG contributor_id, access_type
               people_in_group['WorkGroup'] |= people_in_WG unless people_in_WG.blank?
           when 'Project'
               people_in_project = get_people_in_project contributor_id, access_type
               people_in_group['Project'] |= people_in_project unless people_in_project.blank?
           when 'Institution'
               people_in_institution = get_people_in_institution contributor_id, access_type
               people_in_group['Institution'] |= people_in_institution unless people_in_institution.blank?

         end
      end
      people_in_group
  end

  def get_person person_id, access_type
      person = begin
        Person.find(person_id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
      if person
        return [person.id, "#{person.name}", access_type]
      end
  end

  #review people WG
  def get_people_in_WG wg_id, access_type
      collect_people_details(WorkGroup.find(wg_id),access_type)
  end

  #review people in black list, white list and normal workgroup
  def get_people_in_FG contributor, fg_id=nil, is_white_list=nil, is_black_list=nil
    if is_white_list
      f_group = FavouriteGroup.where(["name = ? AND user_id = ?", "__whitelist__", contributor.user.id]).first
    elsif is_black_list
      f_group = FavouriteGroup.where(["name = ? AND user_id = ?", "__blacklist__", contributor.user.id]).first
    else
      f_group = FavouriteGroup.find_by_id(fg_id)
    end

    if f_group
      return f_group.favourite_group_memberships.collect do |fgm|
        [fgm.person.id, "#{fgm.person.name}", fgm.access_type] if !fgm.blank? and !fgm.person.blank?
      end.compact
    end
  end


  #review people in project
  def get_people_in_project project_id, access_type
    collect_people_details(Project.find(project_id),access_type)
  end

  #review people in institution
  def get_people_in_institution institution_id, access_type
    collect_people_details(Institution.find(institution_id),access_type)
  end

  def collect_people_details resource,access_type
    resource.people.collect do |person|
        [person.id, "#{person.name}", access_type] unless person.blank?
    end.compact
  end

  #review people in network
  def get_people_in_network access_type
    people_in_network = [] #id, name, access_type
    projects = Project.all
    projects.each do |project|
      project.people.each do |person|
        unless person.blank?
          person_identification = [person.id, "#{person.name}"]
          people_in_network.push person_identification if (!people_in_network.include? person_identification)
        end
      end
    end
    people_in_network.collect!{|person| person.push access_type}
    return people_in_network
  end

  #remove duplicate by taking the one with the highest access_type
  def remove_duplicate people_list
     result = []
     #first replace each person in the people list with the highest access_type of this person
     people_list.each do |person|
         result.push(get_max_access_type_element(people_list, person))
     end
     #remove the duplication
     result = result.inject([]) { |result,i| result << i unless result.include?(i); result }
     result

  end

  def get_max_access_type_element(array, element)
     array.each do |a|
        if (element[0] == a[0] && element[2] < a[2])
            element = a;
        end
     end
     return element
  end

  #array2 has precedence
  def precedence array1, array2
    result = []
    result |= array2
     array1.each do |a1|
       check = false
       array2.each do |a2|
        if (a1[0] == a2[0])
            check = true
            break
        end
       end
        if !check
           result.push(a1)
        end
     end
     return result
  end

  #add people which are in whitelist to the people list
  def add_people_in_whitelist(people_list, whitelist)
     result = []
     result |= people_list
     result |= whitelist
     return remove_duplicate(result)
  end

  def is_entirely_private? grouped_people_by_access_type, contributor
    entirely_private = true
    if access_type > Policy::NO_ACCESS
        entirely_private = false
    else
        grouped_people_by_access_type.reject{|key,value| key == Policy::NO_ACCESS || key == Policy::DETERMINED_BY_GROUP}.each_value do |value|
          value.each do |person|
            entirely_private = false if (person[0] != contributor.try(:id))
          end
        end
    end
    return entirely_private
  end

  def concat_roles_to_name grouped_people_by_access_type, creators, asset_housekeepers
    creator_id_array = creators.collect{|c| c.id unless c.blank?}
    asset_housekeeper_id_array = asset_housekeepers.collect{|am| am.id unless am.blank?}
     grouped_people_by_access_type = grouped_people_by_access_type.reject{|key,value| key == Policy::DETERMINED_BY_GROUP}.each_value do |value|
       value.each do |person|
         person[1].concat(' (creator)') if creator_id_array.include?(person[0])
         person[1].concat(' (asset housekeeper)') if asset_housekeeper_id_array.include?(person[0])
       end
     end
    grouped_people_by_access_type
  end

  def allows_action?(action)
    Seek::Permissions::Authorization.access_type_allows_action?(action, self.access_type)
  end

  def destroy_if_redundant
    destroy if assets.none?
  end

end
