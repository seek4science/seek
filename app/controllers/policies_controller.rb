class PoliciesController < ApplicationController
  include WhiteListHelper
  
  before_filter :login_required
  
  def send_policy_data
    request_type = white_list(params[:policy_type])
    entity_type = white_list(params[:entity_type])
    entity_id = white_list(params[:entity_id])
    
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
        entity = entity_type.constantize.find entity_id
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
      contributor_person = (params['is_new_file'] == 'false') ?  User.find_by_id(params['contributor_id'].to_i).try(:person) : current_person
      creators = (params["creators"].blank? ? [] : ActiveSupport::JSON.decode(params["creators"])).uniq
      creators.collect!{|c| Person.find(c[1])}

      resource_class = params[:resource_name].camelize.constantize
      resource = resource_class.find_by_id(params[:resource_id]) || resource_class.new
      policy = resource.policy.set_attributes_with_sharing(params[:policy_attributes])

      privileged_people = {}
      #exclude the current_person from the privileged people
      contributor_person = nil if contributor_person == current_person
      creators.delete(current_person)
      creators.delete(contributor_person)
      privileged_people['contributor'] = [contributor_person] if contributor_person
      privileged_people['creators'] = creators unless creators.empty?

      respond_to do |format|
        format.html { render :partial => "permissions/preview_permissions",
                             :locals => {:policy => policy, :privileged_people => privileged_people,
                                         :updated_can_publish_immediately => updated_can_publish_immediately(resource),
                                         :send_request_publish_approval => !resource.is_waiting_approval?(current_user)}}
      end
  end

  #To check wherether you can publish immediately or need to go through gatekeeper's approval when changing the projects associated with the resource
  def updated_can_publish_immediately resource, project_ids=params[:project_ids]
    cloned_resource = resource.dup
    cloned_resource.policy = resource.policy.deep_copy
    cloned_resource = resource_with_assigned_projects cloned_resource,project_ids
    if !resource.new_record? && resource.is_published?
      updated_can_publish_immediately = true
      #FIXME: need to use User.current_user here because of the way the function tests in PolicyControllerTest work, without correctly creating the session and @request etc
    elsif cloned_resource.gatekeeper_required? && !User.current_user.person.is_asset_gatekeeper_of?(cloned_resource)
      updated_can_publish_immediately = false
    else
      updated_can_publish_immediately = true
    end
    updated_can_publish_immediately
  end

  protected

  def resource_with_assigned_projects resource, project_ids
     if resource.kind_of?Assay
       resource.study = Study.find_by_id(project_ids.to_i)
     elsif resource.kind_of?Study
        resource.investigation = Investigation.find_by_id(project_ids.to_i)
     else
       selected_projects = get_selected_projects project_ids, resource.class.name.underscore
       resource.projects = selected_projects
     end
     resource
  end

  def get_selected_projects project_ids, resource_name
    if (resource_name == 'study') and (!project_ids.blank?)
      investigation = Investigation.find_by_id(project_ids.to_i)
      projects = investigation.nil? ? [] : investigation.projects

      #when resource is assay, id of the study is sent, so get the project_ids from the study
    elsif (resource_name == 'assay') and (!project_ids.blank?)
      study = Study.find_by_id(project_ids.to_i)
      projects = study.nil? ? [] : study.projects
      #normal case, the project_ids is sent
    else
      project_ids = project_ids.blank? ? [] : project_ids.split(',')
      projects = []
      project_ids.each do |id|
        project = Project.find_by_id(id.to_i)
        projects << project if project
      end
    end
    projects
  end
end


