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

    def preview_permissions
      set_no_layout
      grouped_people_by_access_type = request_permission_summary
      respond_to do |format|
        format.html { render :template=>"layouts/preview_permissions", :locals => {:grouped_people_by_access_type => grouped_people_by_access_type}}
      end
    end

    #return the hash: key is access_type, value is the array of people
    def request_permission_summary
        #get params
        sharing_scope = params["sharing_scope"].to_i
        access_type = params["access_type"].to_i

        your_proj_access_type = params["project_access_type"].blank? ? nil : params["project_access_type"].to_i
        #when resource is study, id of the investigation is sent, so get the project_ids from the investigation
        project_ids = []
        if (params[:resource_name] == 'study') and (!params["project_ids"].blank?)
          investigation = Investigation.find_by_id(try_block{params["project_ids"].to_i})
          project_ids = try_block{investigation.projects.collect{|p| p.id}}

        #when resource is assay, id of the study is sent, so get the project_ids from the study
        elsif (params[:resource_name] == 'assay') and (!params["project_ids"].blank?)
          study = Study.find_by_id(try_block{params["project_ids"].to_i})
          project_ids = try_block{study.projects.collect{|p| p.id}}
        #normal case, the project_ids is sent
        else
          project_ids = params["project_ids"].blank? ? [] : params["project_ids"].split(',')
        end

        creators = (params[:creators].blank? ? [] : ActiveSupport::JSON.decode(params[:creators])).uniq

        contributor_types = params["contributor_types"].blank? ? [] : ActiveSupport::JSON.decode(params["contributor_types"])
        new_permission_data = params["contributor_values"].blank? ? {} : ActiveSupport::JSON.decode(params["contributor_values"])

        #build the hash containing contributor_type as key and the people in these groups as value
        people_in_group = {'Person' => [], 'FavouriteGroup' => [], 'WorkGroup' => [], 'Project' => [], 'WhiteList' => [], 'BlackList' => [],'Network' => []}
        #the result return: a hash contain the access_type as key, and array of people as value
        grouped_people_by_access_type = {}

        #Process policy
        #if the item is shared to all sysmo members
        if (sharing_scope == Policy::ALL_SYSMO_USERS)
           people_in_network = get_people_in_network access_type
             unless people_in_network.blank?
               people_in_group['Network'] |= people_in_network
             end
        end
        #if public scope is chosen
        if (sharing_scope == Policy::EVERYONE)
          grouped_people_by_access_type[Policy::PUBLISHING] = access_type
        end

        #Process permissions
        #if share with your project and with all_sysmo_user is chosen
        if (sharing_scope == Policy::ALL_SYSMO_USERS) and !project_ids.blank?
          project_ids.each do |project_id|
            project_id = project_id.to_i
            #add Project to contributor_type
            contributor_types << "Project" if !contributor_types.include? "Project"
            #add one hash {project.id => {"access_type" => sharing[:your_proj_access_type].to_i}} to new_permission_data
            if !new_permission_data.has_key?('Project')
              new_permission_data["Project"] = {project_id => {"access_type" => your_proj_access_type}}
            else
              new_permission_data["Project"][project_id] = {"access_type" => your_proj_access_type}
            end
          end
        end

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
        if (params["use_whitelist"] == 'true')
          people_in_whitelist = get_people_in_FG(nil, true, nil)
          unless people_in_whitelist.blank?
            people_in_group['WhiteList'] |= people_in_whitelist
          end
        end
        #if blacklist/whitelist is used
        if (params["use_blacklist"] == 'true')
          people_in_blacklist = get_people_in_FG(nil, nil, true)
          unless people_in_blacklist.blank?
            people_in_group['BlackList'] |= people_in_blacklist
          end
        end

        #Now make the people in group unique by choosing the highest access_type
        people_in_group['FavouriteGroup']  = remove_duplicate(people_in_group['FavouriteGroup'])
        people_in_group['WorkGroup']  = remove_duplicate(people_in_group['WorkGroup'])
        people_in_group['Project']  = remove_duplicate(people_in_group['Project'])

        #Now process precedence with the order [network, project, wg, fg, person]
        filtered_people = people_in_group['Network']
        filtered_people = precedence(filtered_people, people_in_group['Project'])
        filtered_people = precedence(filtered_people, people_in_group['WorkGroup'])
        filtered_people = precedence(filtered_people, people_in_group['FavouriteGroup'])
        filtered_people = precedence(filtered_people, people_in_group['Person'])

        #add people in white list
        filtered_people = add_people_in_whitelist(filtered_people, people_in_group['WhiteList'])
        #remove people in blacklist
        filtered_people = remove_people_in_blacklist(filtered_people, people_in_group['BlackList'])

        #add creators and assign them the Policy::EDITING right
        creators.collect!{|c| [c[1] ,c[0], Policy::EDITING]}
        filtered_people = add_people_in_whitelist(filtered_people, creators)

        #remove current_user
        filtered_people = filtered_people.reject{|person| person[0] == current_user.id}

        #sort people by name
        filtered_people = filtered_people.sort{|a,b| a[1] <=> b[1]}

        #group people by access_type
        grouped_people_by_access_type.merge!(filtered_people.group_by{|person| person[2]})

        #only store (people in backlist) + (people in people_in_group['Person'] with no access) to the group of access_type=Policy::NO_ACCESS
        people_with_no_access = []
        people_with_no_access.concat(people_in_group['BlackList']) unless people_in_group['BlackList'].blank?
        people_with_no_access.concat(people_in_group['Person'].group_by{|person| person[2]}[Policy::NO_ACCESS]) unless people_in_group['Person'].group_by{|person| person[2]}[Policy::NO_ACCESS].blank?
        people_with_no_access.uniq!
        unless people_with_no_access.blank?
           grouped_people_by_access_type[Policy::NO_ACCESS] = people_with_no_access.sort{|a,b| a[1] <=> b[1]}
        end

        #sort by key of the hash
        grouped_people_by_access_type = Hash[grouped_people_by_access_type.sort]

        return grouped_people_by_access_type
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

    #remove people which are in blacklist from the people list
    def remove_people_in_blacklist(people_list, blacklist)
       result = []
       result |= people_list
       people_list.each do |person|
         check = false
         blacklist.each do |person_in_bl|
          if (person[0] == person_in_bl[0])
            check = true
            break
          end
         end
         if check
            result.delete person
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
end


