class Policy < ApplicationRecord
  has_many :permissions, -> { order('created_at ASC') },
           dependent: :destroy,
           autosave: true,
           inverse_of: :policy

  # basically the same as validates_numericality_of :access_type
  # but with a more generic error message because our users don't know what
  # sharing_scope and access_type are.
  validates_each(:access_type) do |record, attr, value|
    raw_value = record.send("#{attr}_before_type_cast") || value
    begin
      Kernel.Float(raw_value)
    rescue ArgumentError, TypeError
      record.errors.add(:base, 'Sharing policy is invalid') unless value.is_a? Integer
    end
  end

  validates :access_type, numericality: { less_than_or_equal_to: -> (_) { Seek::Config.max_all_visitors_access_type }, # This needs to be a proc so the setting can be changed without restarting the app
                                          message: 'is too permissive' }

  alias_attribute :title, :name

  after_commit :queue_update_auth_table
  after_commit :queue_rdf_generation_job
  before_save :update_timestamp_if_permissions_change

  def update_timestamp_if_permissions_change
    update_timestamp if changed_for_autosave?
  end

  def queue_update_auth_table
    unless (saved_changes.keys - ['updated_at']).empty? || assets.empty?
      AuthLookupUpdateQueue.enqueue(assets)
    end
  end

  def queue_rdf_generation_job
    supported_assets = assets.select(&:rdf_supported?)
    unless (saved_changes.keys - ['updated_at']).empty? || supported_assets.empty?
      RdfGenerationQueue.enqueue(supported_assets)
    end
  end

  def assets
    Seek::Util.authorized_types.collect do |type|
      type.where(policy_id: id)
    end.flatten.uniq
  end

  # *****************************************************************************
  #  This section defines constants for "access_type" values

  # NB! It is critical to all algorithms using these constants, that they
  # have their integer values increased along with the access they provide
  # (so, for example, "editing" should have greater value than "viewing")

  # sharing_scope - NO LONGER USED
  PRIVATE = 0
  ALL_USERS = 2
  EVERYONE = 4

  # access_type
  DETERMINED_BY_GROUP = -1  # used for allowlist/denylist (meaning that it doesn't matter what value this field has)
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

  # makes a copy of the policy, and its associated permissions.
  def deep_copy
    copy = dup
    copied_permissions = permissions.collect(&:dup)
    copied_permissions.each { |p| copy.permissions << p }
    copy
  end

  # checks that there are permissions for the provided contributor, for the access_type (or higher)
  def permission_granted?(contributor, access_type)
    permissions.where(contributor:contributor).where('access_type >= ?',access_type).any?
  end

  def self.new_for_upload_tool(resource, recipient)
    policy = resource.build_policy(name: 'auto',
                                   access_type: Policy::NO_ACCESS)
    policy.permissions.build contributor_type: 'Person', contributor_id: recipient, access_type: Policy::ACCESSIBLE
    policy
  end

  def self.new_from_email(resource, recipients, accessors)
    policy = resource.build_policy(name: 'auto',
                                   access_type: Policy::NO_ACCESS)
    if recipients
      recipients.each do |id|
        policy.permissions.build contributor_type: 'Person', contributor_id: id, access_type: Policy::EDITING
      end
    end

    if accessors
      accessors.each do |id|
        policy.permissions.build contributor_type: 'Person', contributor_id: id, access_type: Policy::ACCESSIBLE
      end
    end

    policy
  end

  def set_attributes_with_sharing(policy_params)
    # if no data about sharing is given, it should be some user (not the owner!)
    # who is editing the asset - no need to do anything with policy / permissions: return success
    tap do |policy|
      if policy_params.present?
        # Set attributes on the policy
        policy.access_type = policy_params[:access_type]
        if policy.access_type.nil? || policy.access_type > Policy::NO_ACCESS
          policy.sharing_scope = nil # This field should not be used anymore
        end

        # Set attributes on the policy's permissions
        if policy_params[:permissions_attributes]
          current_permissions = policy.permissions
          new_permissions = policy_params[:permissions_attributes].values.map do |perm_params|
            # See if a permission already exists with that contributor
            permission = current_permissions.detect do |p|
              p.contributor_type == perm_params[:contributor_type] &&
                p.contributor_id == perm_params[:contributor_id].to_i
            end
            permission ||= policy.permissions.build

            permission.tap { |p| p.assign_attributes(perm_params) }
          end

          # Get the unused permissions and mark them for destruction (after policy is saved)
          (current_permissions - new_permissions).each(&:mark_for_destruction)
        end
      end
    end
  end

  def update_with_bulk_sharing_policy(policy_params)

    tap do |policy|
      if policy_params
        # Set attributes on the policy
        policy.access_type = policy_params[:access_type] unless policy_params[:access_type].nil?

        if policy.access_type.nil? || policy.access_type > Policy::NO_ACCESS
          policy.sharing_scope = nil # This field should not be used anymore
        end

        # Set attributes on the policy's permissions
        if policy_params[:permissions_attributes]
          current_permissions = policy.permissions

          policy_params[:permissions_attributes].values.map do |perm_params|
            permission = current_permissions.detect do |p|
              p.contributor_type == perm_params[:contributor_type] &&
                  p.contributor_id == perm_params[:contributor_id].to_i
            end

            permission ||= policy.permissions.create
            permission.tap {|p| p.assign_attributes(perm_params)}
            permission.save

            current_permissions = policy.permissions
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
    project.default_policy
  end

  def self.private_policy
    Policy.new(name: 'default private',
               access_type: NO_ACCESS,
               use_allowlist: false,
               use_denylist: false)
  end

  def self.registered_users_accessible_policy
    Policy.new(name: 'default accessible',
               access_type: ACCESSIBLE,
               use_allowlist: false,
               use_denylist: false)
  end

  def self.public_policy
    Policy.new(name: 'default public',
               access_type: ACCESSIBLE)
  end

  def self.projects_policy(projects = [])
    policy = Policy.new(name: 'default projects policy',
                        access_type: NO_ACCESS)
    projects.each do |project|
      policy.permissions.build(contributor: project, access_type: ACCESSIBLE)
    end
    policy
  end

  # The default policy to use when creating authorized items if no other policy is specified
  def self.default
    Policy.new(name: 'default policy', access_type: Seek::Config.default_all_visitors_access_type)
  end

  # translates access type codes into human-readable form
  def self.get_access_type_wording(access_type, downloadable = false)
    case access_type
    when Policy::DETERMINED_BY_GROUP
      I18n.t('access.determined_by_group')
    when Policy::NO_ACCESS
      I18n.t('access.no_access')
    when Policy::VISIBLE
      downloadable ? I18n.t('access.visible_downloadable') : I18n.t('access.visible')
    when Policy::ACCESSIBLE
      downloadable ? I18n.t('access.accessible_downloadable') : I18n.t('access.accessible')
    when Policy::EDITING
      downloadable ? I18n.t('access.editing_downloadable') : I18n.t('access.editing')
    when Policy::MANAGING
      I18n.t('access.managing')
    else
      'Invalid access type'
    end
  end

  # extracts the "settings" of the policy, discarding other information
  # (e.g. contributor, creation time, etc.)
  def get_settings
    settings = {}
    settings['access_type'] = access_type
    settings['use_allowlist'] = use_allowlist
    settings['use_denylist'] = use_denylist
    settings
  end

  # extract the "settings" from all permissions associated to the policy;
  # creates array containing 2-item arrays per each policy in the form:
  # [ ... , [ permission_id, {"contributor_id" => id, "contributor_type" => type, "access_type" => access} ]  , ...  ]
  def get_permission_settings
    p_settings = []
    permissions.each do |p|
      # standard parameters for all contributor types
      params_hash = {}
      params_hash['contributor_id'] = p.contributor_id
      params_hash['contributor_type'] = p.contributor_type
      params_hash['access_type'] = p.access_type
      params_hash['contributor_name'] = (p.contributor_type == 'Person' ? (p.contributor.first_name + ' ' + p.contributor.last_name) : p.contributor.name)

      # some of the contributor types will have special additional parameters
      case p.contributor_type
      when 'FavouriteGroup'
        params_hash['allowlist_or_denylist'] = [FavouriteGroup::ALLOWLIST_NAME, FavouriteGroup::DENYLIST_NAME].include?(p.contributor.name)
      end

      p_settings << [p.id, params_hash]
    end

    p_settings
  end

  def private?
    access_type == Policy::NO_ACCESS && permissions.where('access_type > ?', Policy::NO_ACCESS).empty?
  end

  def public?
    access_type && access_type > Policy::NO_ACCESS && sharing_scope != Policy::ALL_USERS
  end

  # item is acccessible to members of the projects passed. Ignores additional restrictions, such as additional permissions to block particular members.
  # if items is a downloadable_asset it needs to be ACCESSIBLE, otherwise just VISIBLE
  def projects_accessible?(projects, downloadable_asset)
    lowest_access_type = downloadable_asset ? Policy::ACCESSIBLE : Policy::VISIBLE
    return true if access_type >= lowest_access_type
    Array(projects).select do |project|
      !permission_granted?(project,lowest_access_type)
    end.empty?
  end

  # return the hash: key is access_type, value is the array of people
  def summarize_permissions(creators = [User.current_user.try(:person)], asset_housekeepers = [], contributor = User.current_user.try(:person))
    # build the hash containing contributor_type as key and the people in these groups as value,exception:'Public' holds the access_type as the value
    people_in_group = { 'Person' => [],
                        'FavouriteGroup' => [],
                        'WorkGroup' => [],
                        'Project' => [],
                        'Programme' => [],
                        'Institution' => [],
                        'AllowList' => [],
                        'DenyList' => [],
                        'Network' => [],
                        'Public' => 0 }
    # the result return: a hash contain the access_type as key, and array of people as value
    grouped_people_by_access_type = {}

    people_in_group['Public'] = access_type

    permissions_to_people_group permissions, people_in_group

    # Now make the people in group unique by choosing the highest access_type
    people_in_group['FavouriteGroup'] = remove_duplicate(people_in_group['FavouriteGroup'])
    people_in_group['WorkGroup'] = remove_duplicate(people_in_group['WorkGroup'])
    people_in_group['Project'] = remove_duplicate(people_in_group['Project'])
    people_in_group['Programme'] = remove_duplicate(people_in_group['Programme'])
    people_in_group['Institution'] = remove_duplicate(people_in_group['Institution'])

    # Now process precedence with the order [network, institution, project, wg, fg, person]
    filtered_people = people_in_group['Network']
    filtered_people = precedence(filtered_people, people_in_group['Institution'])
    filtered_people = precedence(filtered_people, people_in_group['Programme'])
    filtered_people = precedence(filtered_people, people_in_group['Project'])
    filtered_people = precedence(filtered_people, people_in_group['WorkGroup'])
    filtered_people = precedence(filtered_people, people_in_group['FavouriteGroup'])
    filtered_people = precedence(filtered_people, people_in_group['Person'])

    # add people in allowlist
    filtered_people = add_people_in_allowlist(filtered_people, people_in_group['AllowList'])
    # add people in denylist
    filtered_people = precedence(filtered_people, people_in_group['DenyList'])

    # add creators and assign them the Policy::EDITING right
    creator_array = creators.collect { |c| [c.id, c.name.to_s, Policy::EDITING] unless c.blank? }
    filtered_people = add_people_in_allowlist(filtered_people, creator_array)

    # add contributor
    filtered_people = add_people_in_allowlist(filtered_people, [[contributor.id, contributor.name.to_s, Policy::MANAGING]]) unless contributor.blank?

    # sort people by name
    filtered_people = filtered_people.sort { |a, b| a[1] <=> b[1] }

    # group people by access_type
    grouped_people_by_access_type.merge!(filtered_people.group_by { |person| person[2] })

    asset_housekeeper_array = asset_housekeepers.collect { |am| [am.id, am.name.to_s, Policy::MANAGING] unless am.blank? }
    if grouped_people_by_access_type[Policy::MANAGING].blank?
      grouped_people_by_access_type[Policy::MANAGING] = asset_housekeeper_array
    else
      grouped_people_by_access_type[Policy::MANAGING] |= asset_housekeeper_array
    end

    # concat the roles to a person name
    concat_roles_to_name grouped_people_by_access_type, creators, asset_housekeepers

    # use Policy::DETERMINED_BY_GROUP to store public group if access_type for public > 0
    grouped_people_by_access_type[Policy::DETERMINED_BY_GROUP] = people_in_group['Public'] if people_in_group['Public'] > 0

    # sort by key of the hash
    grouped_people_by_access_type = Hash[grouped_people_by_access_type.sort]

    grouped_people_by_access_type
  end

  def permissions_to_people_group(permissions, people_in_group)
    permissions.each do |permission|
      contributor_id = permission.contributor_id
      access_type = permission.access_type

      if permission.contributor_type == 'FavouriteGroup'
        details = get_people_in_FG nil, contributor_id
      else
        details = permission.affected_people.collect do |person|
          [person.id, person.name.to_s, access_type] unless person.blank?
        end.compact
      end

      people_in_group[permission.contributor_type] |= details unless details.blank?
    end

    people_in_group
  end

  # REVIEW: people in denylist, allowlist and normal workgroup
  def get_people_in_FG(contributor, fg_id = nil, is_allowed_list = nil, is_denied_list = nil)
    f_group = if is_allowed_list
                FavouriteGroup.where(['name = ? AND user_id = ?', FavouriteGroup::ALLOWLIST_NAME, contributor.user.id]).first
              elsif is_denied_list
                FavouriteGroup.where(['name = ? AND user_id = ?', FavouriteGroup::DENYLIST_NAME, contributor.user.id]).first
              else
                FavouriteGroup.find_by_id(fg_id)
              end

    if f_group
      return f_group.favourite_group_memberships.collect do |fgm|
        [fgm.person.id, fgm.person.name.to_s, fgm.access_type] if !fgm.blank? && !fgm.person.blank?
      end.compact
    end
  end

  def collect_people_details(resource, access_type)
    resource.people.collect do |person|
      [person.id, person.name.to_s, access_type] unless person.blank?
    end.compact
  end

  # remove duplicate by taking the one with the highest access_type
  def remove_duplicate(people_list)
    result = []
    # first replace each person in the people list with the highest access_type of this person
    people_list.each do |person|
      result.push(get_max_access_type_element(people_list, person))
    end
    # remove the duplication
    result = result.each_with_object([]) { |i, result| result << i unless result.include?(i); }
    result
  end

  def get_max_access_type_element(array, element)
    array.each do |a|
      element = a if element[0] == a[0] && element[2] < a[2]
    end
    element
  end

  # array2 has precedence
  def precedence(array1, array2)
    result = []
    result |= array2
    array1.each do |a1|
      check = false
      array2.each do |a2|
        if a1[0] == a2[0]
          check = true
          break
        end
      end
      result.push(a1) unless check
    end
    result
  end

  # add people which are in allowlist to the people list
  def add_people_in_allowlist(people_list, allowlist)
    result = []
    result |= people_list
    result |= allowlist
    remove_duplicate(result)
  end

  def concat_roles_to_name(grouped_people_by_access_type, creators, asset_housekeepers)
    creator_id_array = creators.collect { |c| c.id unless c.blank? }
    asset_housekeeper_id_array = asset_housekeepers.collect { |am| am.id unless am.blank? }
    grouped_people_by_access_type = grouped_people_by_access_type.reject { |key, _value| key == Policy::DETERMINED_BY_GROUP }.each_value do |value|
      value.each do |person|
        person[1].concat(' (creator)') if creator_id_array.include?(person[0])
        person[1].concat(' (asset housekeeper)') if asset_housekeeper_id_array.include?(person[0])
      end
    end
    grouped_people_by_access_type
  end

  def allows_action?(action)
    Seek::Permissions::Authorization.access_type_allows_action?(action, access_type)
  end

  def destroy_if_redundant
    destroy if assets.none?
  end

  # utility to get all items associated with this policy.
  def associated_items
    types = (Seek::Util.authorized_types + [OpenbisEndpoint])
    items = types.collect do |type|
      type.where(policy_id: id)
    end
    items |= Project.where(default_policy_id: id)
    items.flatten.compact.uniq
  end
end
