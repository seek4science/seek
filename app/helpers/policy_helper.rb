module PolicyHelper
  def policy_selection_options(access_types = nil, resource = nil, selected_access_type = nil)
    access_types ||= [Policy::NO_ACCESS, Policy::VISIBLE, Policy::ACCESSIBLE, Policy::EDITING, Policy::MANAGING]

    unless resource.try(:is_downloadable?)
      access_types.delete(Policy::ACCESSIBLE)

      if selected_access_type == Policy::ACCESSIBLE
        # handle access_type = ACCESSIBLE, and !resource.is_downloadable?
        # In that case set access_type to VISIBLE
        selected_access_type = Policy::VISIBLE
      end
    end

    options_for_select(access_types.map { |t| [Policy.get_access_type_wording(t, resource.try(:is_downloadable?)), t] },
                       selected_access_type)
  end

  def project_policy_selection_options(access_types = nil, resource = nil, selected_access_type = nil)
    access_types ||= [Policy::NO_ACCESS, Policy::VISIBLE, Policy::ACCESSIBLE, Policy::EDITING, Policy::MANAGING]

    options_for_select(access_types.map { |t| [Policy.get_access_type_wording(t, true), t] },
                       selected_access_type)
  end

  # check if there are overlapped people in permissions and of privileged_people
  # if yes, compare the access type of them
  # and keep the one with higher access type
  def uniq_people_permissions_and_privileged_people(permissions, privileged_people)
    uniq_permissions_by_contributor permissions

    people_from_permissions = permissions.select { |p| p.contributor_type == 'Person' }.collect(&:contributor)

    privileged_people.each do |key, value|
      value.each do |v|
        next unless people_from_permissions.include?(v)
        permission_index = permissions.index { |p| p.contributor == v }
        access_type_from_permission = permissions[permission_index].access_type
        access_type_from_privileged_person = (key == 'contributor') ? Policy::MANAGING : Policy::EDITING
        if (access_type_from_privileged_person >= access_type_from_permission)
          permissions.slice!(permission_index)
        else
          privileged_people[key].delete(v)
          privileged_people.delete(key) if privileged_people[key].empty?
        end
      end
    end
    [permissions, privileged_people]
  end

  def group_by_access_type(permissions, privileged_people, downloadable = false)
    grouped_contributors = {}
    # Group "download" permissions (i.e. from a default policy) in with "view" permissions if the resource is not downloadable
    grouped_permissions = permissions.group_by do |p|
      if !downloadable && p.access_type == Policy::ACCESSIBLE
        Policy::VISIBLE
      else
        p.access_type
      end
    end

    grouped_permissions.each do |access, permissions|
      grouped_contributors[access] = permissions.map(&:contributor)
    end

    (privileged_people['creators'] || []).each do |creator|
      grouped_contributors[Policy::EDITING] ||= []
      grouped_contributors[Policy::EDITING].unshift(creator)
    end

    (privileged_people['contributor'] || []).each do |contributor|
      grouped_contributors[Policy::MANAGING] ||= []
      grouped_contributors[Policy::MANAGING].unshift(contributor)
    end

    grouped_contributors
  end

  def process_privileged_people(privileged_people, resource_name)
    html = ''
    unless privileged_people.blank?
      html << '<h3> Privileged people:</h3>'
      privileged_people.each do |key, value|
        value.each do |v|
          html << "<p class='privileged_person'>"
          if key == 'contributor'
            html << "#{h(v.name)} can #{Policy.get_access_type_wording(Policy::MANAGING, resource_name.camelize.constantize.new.try(:is_downloadable?)).downcase} as an uploader"
          elsif key == 'creators'
            html << "#{h(v.name)} can #{Policy.get_access_type_wording(Policy::EDITING, resource_name.camelize.constantize.new.try(:is_downloadable?)).downcase} as a creator"
          end
          html << '</p>'
        end
      end
    end

    html.html_safe
  end

  def uniq_permissions_by_contributor(permissions)
    # Choose the one which has the maximum access_type
    permissions.each_with_index do |p, _index|
      permissions_with_the_same_contributor = permissions.select { |per| per.contributor == p.contributor }
      next unless permissions_with_the_same_contributor.size > 1
      max_access_type_per = permissions_with_the_same_contributor.max_by(&:access_type)
      permissions_with_the_same_contributor.delete(max_access_type_per)
      permissions_with_the_same_contributor.each { |p| permissions.delete(p) }
    end
  end

  def policy_hash(policy, associated_projects)
    project_ids = associated_projects.map(&:id)
    hash = { access_type: policy.access_type }

    hash[:permissions] = policy.permissions.map do |permission|
      h = { id: permission.id,
            access_type: permission.access_type,
            contributor_id: permission.contributor_id,
            contributor_type: permission.contributor_type,
            index: permission.id }
      # Mark associated project permissions as "mandatory"
      if permission.contributor_type == 'Project' && project_ids.include?(permission.contributor_id)
        project_ids.delete(permission.contributor_id)
        h[:isMandatory] = true
      end

      h[:title] = permission_title(permission)

      h
    end

    # Add permissions for associated projects if they didn't already exist. Use "public" access type
    associated_projects.select { |p| project_ids.include?(p.id) }.each do |project|
      hash[:permissions] << { access_type: policy.access_type,
                              contributor_id: project.id,
                              contributor_type: 'Project',
                              title: project.title,
                              isMandatory: true }
    end

    hash
  end

  def policy_json(policy, associated_projects)
    policy_hash(policy, associated_projects).to_json.html_safe
  end

  def project_policies_json(projects)
    hash = {}

    projects.each do |p|
      hash[p.id] = policy_hash(p.default_policy, [p]) if p.use_default_policy
    end

    hash.to_json.html_safe
  end

  def permission_title(permission, member_prefix: false, icon: false)
    if permission.is_a?(Permission)
      type = permission.contributor_type
      contributor = permission.contributor
    else
      type = permission.class.name
      contributor = permission
    end

    if type == 'Person'
      text = "#{contributor.first_name} #{contributor.last_name}"
    elsif type == 'WorkGroup'
      text = "#{member_prefix ? 'Members of ' : ''}#{contributor.project.title} @ #{contributor.institution.title}"
    else
      text = "#{member_prefix ? 'Members of ' : ''}#{contributor.title}"
    end

    if icon
      content_tag(:span, class: 'type-icon-wrapper') do
        image_tag(asset_path(icon_filename_for_key(type.underscore)), class: 'type-icon')
      end.html_safe + " #{text}"
    else
      text
    end
  end

  def access_type_key(access_type)
    case access_type
      when Policy::MANAGING
        'manage'
      when Policy::EDITING
        'edit'
      when Policy::ACCESSIBLE
        'download'
      when Policy::VISIBLE
        'view'
      when Policy::NO_ACCES
        'no_access'
    end
  end

end
