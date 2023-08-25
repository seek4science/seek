class PoliciesController < ApplicationController
  before_action :login_required

  def send_policy_data
    request_type = sanitized_text(params[:policy_type])
    entity_type = sanitized_text(params[:entity_type])
    entity_id = sanitized_text(params[:entity_id])

    # NB! default policies now are only suppoted by Projects (but not Institutions / WorkGroups) -
    # so supplying any other type apart from Project will cause the return error message
    if request_type.downcase == "default" && entity_type == "Project"
      supported = true

      # check that current user (the one sending AJAX request to get data from this handler)
      # is a member of the project for which they try to get the default policy
      authorized = current_person.projects.include? Project.find(entity_id)
    else
      supported = false
    end

    # only fetch all the policy/permissions settings if authorized to do so & only for request types that are supported
    if supported && authorized
      begin
        entity = safe_class_lookup(entity_type).find entity_id
        found_entity = true
        policy = nil

        if entity.default_policy
          # associated default policy exists
          found_exact_match = true
          policy = entity.default_policy
        else
          # no associated default policy - use system default
          found_exact_match = false
          policy = Policy.default()
        end

      rescue ActiveRecord::RecordNotFound
        found_entity = false
      end
    end

    respond_to do |format|
      format.json {
        if supported && authorized && found_entity
          policy_settings = policy.get_settings
          permission_settings = policy.get_permission_settings

          render :json => {:status => 200, :found_exact_match => found_exact_match, :policy => policy_settings,
                           :permission_count => permission_settings.length, :permissions => permission_settings }
        elsif supported && authorized && !found_entity
          render :json => {:status => 404, :error => "Couldn't find #{entity_type} with ID #{entity_id}."}
        elsif supported && !authorized
          render :json => {:status => 403, :error => "You are not authorized to view policy for that #{entity_type}."}
        else
          render :json => {:status => 400, :error => "Requests for default #{t('project')} policies are only supported at the moment."}
        end
      }
    end
  end

  def preview_permissions
    resource_class = safe_class_lookup(params[:resource_name].camelize)
    resource = nil
    resource = resource_class.find_by_id(params[:resource_id]) if params[:resource_id]
    resource ||= resource_class.new
    projects = Project.where(id: (params[:project_ids] || '').split(','))
    ucpi = updated_can_publish_immediately(resource, projects)
    policy = resource.policy.set_attributes_with_sharing(policy_params)
    trying_to_publish = resource.is_published?
    contributor_person = resource.new_record? ? current_person : resource.contributor.try(:person)
    creators = Person.find((params[:creators] || '').split(',').compact.uniq)

    privileged_people = {}
    #exclude the current_person from the privileged people
    contributor_person = nil if contributor_person == current_person
    creators.delete(current_person)
    creators.delete(contributor_person)
    privileged_people['contributor'] = [contributor_person] if contributor_person
    privileged_people['creators'] = creators unless creators.empty?

    respond_to do |format|
      format.html { render partial: 'permissions/preview_permissions',
                           locals: { resource: resource, policy: policy, privileged_people: privileged_people,
                                     updated_can_publish_immediately: ucpi || !resource.policy.access_type_changed? || !trying_to_publish,
                                     send_request_publish_approval: !resource.is_waiting_approval?(current_user),
                                     publish_approval_rejected: resource.is_rejected?}}
    end
  end

  #To check whether you can publish immediately or need to go through gatekeeper's approval when changing the projects associated with the resource
  def updated_can_publish_immediately(resource, projects)
    projects = [projects] if projects.is_a?(Project)
    if resource.is_published?
      true unless resource.new_record?
    elsif projects.empty?
      !resource.gatekeeper_required?
    else
      #FIXME: need to use User.current_user here because of the way the function tests in PolicyControllerTest work, without correctly creating the session and @request etc
      projects.none? { |p| p.asset_gatekeepers.any? } || projects.any? { |p| User.current_user.person.is_asset_gatekeeper?(p) }
    end
  end
end
