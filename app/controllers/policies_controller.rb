require 'white_list_helper'

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
      authorized = current_user.person.projects.include? Project.find(entity_id)
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
          render :json => {:status => 400, :error => "Requests for default project policies are only supported at the moment."}
        end
      }
    end
  end

  def request_permission_summary
    #get sharing_scope and access_type
    sharing =  ActiveSupport::JSON.decode(params[:sharing])
    sharing_scope = sharing["sharing_scope"]
    access_type = sharing["access_type"]
    project_id = sharing["project_id"].blank? ? nil : sharing["project_id"]
    your_proj_access_type = sharing["project_access_type"].blank? ? nil : sharing["project_access_type"]

    contributor_types = sharing["contributor_types"].blank? ? [] : ActiveSupport::JSON.decode(sharing["contributor_types"])
    new_permission_data = sharing["contributor_values"].blank? ? {} : ActiveSupport::JSON.decode(sharing["contributor_values"])

    #if share with your project is chosen
    if (sharing_scope == Policy::ALL_SYSMO_USERS) and project_id
      #add Project to contributor_type
      contributor_types << "Project" if !contributor_types.include? "Project"
      #add one hash {project.id => {"access_type" => sharing[:your_proj_access_type].to_i}} to new_permission_data
      if !new_permission_data.has_key?('Project')
        new_permission_data["Project"] = {project_id => {"access_type" => your_proj_access_type}}
      else
        new_permission_data["Project"][project_id] = {"access_type" => your_proj_access_type}
      end
    end

    #build the hash containing contributor_type as key and the people in these groups as value
    people_in_group = {'Person' => [], 'FavouriteGroup' => [], 'WorkGroup' => [], 'Project' => [], 'WhiteList' => [], 'BlackList' => [],'Network' => []}
    contributor_types.each do |contributor_type|
       case contributor_type
         when 'Person'
           new_permission_data['Person'].each do |key, value|
             person = get_person key, value.values.first
             unless person.blank?
               people_in_group['Person'] << person
             end
           end
         when 'FavouriteGroup'
           new_permission_data['FavouriteGroup'].each_key do |key|
             people_in_FG = get_people_in_FG key
             unless people_in_FG.blank?
               people_in_group['FavouriteGroup'] |= people_in_FG
             end
           end
         when 'WorkGroup'
           new_permission_data['WorkGroup'].each do |key, value|
             people_in_WG = get_people_in_WG key, value.values.first
             unless people_in_WG.blank?
               people_in_group['WorkGroup'] |= people_in_WG
             end
           end
         when 'Project'
           new_permission_data['Project'].each do |key, value|
              people_in_project = get_people_in_project key, value.values.first
              unless people_in_project.blank?
                people_in_group['Project'] |= people_in_project
              end
           end
       end
    end

    #if blacklist/whitelist is used
    if sharing["use_whitelist"]
      people_in_whitelist = get_people_in_FG(nil, true, nil)
      unless people_in_whitelist.blank?
        people_in_group['WhiteList'] |= people_in_whitelist
      end
    end
    #if blacklist/whitelist is used
    if sharing["use_blacklist"]
      people_in_blacklist = get_people_in_FG(nil, nil, true)
      unless people_in_blacklist.blank?
        people_in_group['BlackList'] |= people_in_blacklist
      end
    end

    #if the item is shared to all sysmo members
    if (sharing_scope == Policy::ALL_SYSMO_USERS)
       people_in_network = get_people_in_network access_type
         unless people_in_network.blank?
           people_in_group['Network'] |= people_in_network
         end
    end

    #Now make the people in group unique by choosing the highest access_type
    people_in_group['FavouriteGroup']  = remove_duplicate(people_in_group['FavouriteGroup'])
    people_in_group['WorkGroup']  = remove_duplicate(people_in_group['WorkGroup'])
    people_in_group['Project']  = remove_duplicate(people_in_group['Project'])

    #Now process precedence with the order [network, project, wg, fg, person, whitelist, blacklist]
    filtered_people = people_in_group['Network']
    filtered_people = precedence(filtered_people, people_in_group['Project'])
    filtered_people = precedence(filtered_people, people_in_group['WorkGroup'])
    filtered_people = precedence(filtered_people, people_in_group['FavouriteGroup'])
    filtered_people = precedence(filtered_people, people_in_group['Person'])
    filtered_people = precedence(filtered_people, people_in_group['WhiteList'])
    filtered_people = remove_element_from_blacklist(filtered_people, people_in_group['BlackList'])
    #remove current_user
    #group people by access_type
    grouped_people = filtered_people.group_by{|person| person[2]}

    respond_to do |format|
      format.json { render :json => {:status => 200, :people_in_group => grouped_people}}
    end
  end

  def get_person person_id, access_type
    person = Person.find(person_id)
    if person
      return [person.id, "#{person.first_name} #{person.last_name}", access_type]
    end
  end

  #review people WG
  def get_people_in_WG wg_id, access_type
      w_group = WorkGroup.find(wg_id)
    if w_group
      people_in_wg = [] #id, name, access_type
      w_group.group_memberships.each do |gm|
        people_in_wg.push [gm.person.id, "#{gm.person.first_name} #{gm.person.last_name}", access_type ]
      end
    end
    return people_in_wg
  end

  #review people in black list, white list and normal workgroup
  def get_people_in_FG fg_id=nil, is_white_list=nil, is_black_list=nil
    if is_white_list
      f_group = FavouriteGroup.find(:all, :conditions => ["name = ? AND user_id = ?", "__whitelist__", current_user.id ]).first
    elsif is_black_list
      f_group = FavouriteGroup.find(:all, :conditions => ["name = ? AND user_id = ?", "__blacklist__", current_user.id ]).first
    else
      f_group = FavouriteGroup.find(fg_id, :conditions => { :user_id => current_user.id } )
    end

    if f_group
      people_in_FG = [] #id, name, access_type
      f_group.favourite_group_memberships.each do |fgm|
        people_in_FG.push [fgm.person.id, "#{fgm.person.first_name} #{fgm.person.last_name}", fgm.access_type]
      end
      return people_in_FG
    end
  end


  #review people in project
  def get_people_in_project project_id, access_type
      project = Project.find(project_id)
    if project
      people_in_project = [] #id, name, access_type
      project.people.each do |person|
        people_in_project.push [person.id, "#{person.first_name} #{person.last_name}", access_type]
      end
      return people_in_project
    end
  end

  #review people in network
  def get_people_in_network access_type
    people_in_network = [] #id, name, access_type
    projects = Project.find(:all)
    projects.each do |project|
      project.people.each do |person|
        person_identification = [person.id, "#{person.first_name} #{person.last_name}"]
        people_in_network.push person_identification if (!people_in_network.include? person_identification)
      end
    end
    people_in_network.collect!{|person| person.push access_type}
    return people_in_network
  end

#remove duplicate by taking the one with the highest access_type
def remove_duplicate array
   result = []
   array.each do |a|
       result.push(get_max_access_type(array, a))
   end
   result = result.inject([]) { |result,i| result << i unless result.include?(i); result }
   result

end

def get_max_access_type(array, element)
   array.each do |a|
      if (element[0] == a[0] && element[2] < a[2])
          element = a;
      end
   end
   return element
end

def precedence array1, array2
   result = array2
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

#remove elements which are in blacklist
def remove_element_from_blacklist(array, blacklist)
   result = array
   array.each do |a|
     check = false
     blacklist.each do |bl|
      if (a[0] == bl[0])
          check = true
          break
      end
     end
     if check
        result.delete a
     end
   end
   return result
end

end