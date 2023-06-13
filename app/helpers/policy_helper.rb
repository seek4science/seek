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

  def project_policy_json(project)
    hash = policy_hash(project.default_policy, [project]) if project.use_default_policy
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

  def self.permission_changed_item_class(permission, policy_params)
     mark = nil
       unless policy_params[:permissions_attributes].nil?
        policy_params[:permissions_attributes].values.map do |perm_params|
            if  permission.contributor_type == perm_params[:contributor_type] && permission.contributor_id == perm_params[:contributor_id].to_i
            mark = "sharing_permission_changed"
          end
        end
       end
    mark
  end

  ACCESS_TYPE_MAP = {
      Policy::MANAGING => 'manage',
      Policy::EDITING => 'edit',
      Policy::ACCESSIBLE => 'download',
      Policy::VISIBLE => 'view',
      Policy::NO_ACCESS => 'no_access'
  }

  INVERSE_ACCESS_TYPE_MAP = ACCESS_TYPE_MAP.invert

  def self.access_type_key(access_type)
    ACCESS_TYPE_MAP[access_type]
  end

  def self.key_access_type(key)
    INVERSE_ACCESS_TYPE_MAP[key.to_s]
  end

end
