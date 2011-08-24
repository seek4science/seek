module Seek
  module Publishing

    def self.included(base)
      base.before_filter :set_asset, :only=>[:preview_publish,:publish]
    end

    def preview_publish
      asset_type_name = @template.text_for_resource @asset

      respond_to do |format|
        format.html { render :template=>"assets/publish/preview",:locals=>{:asset_type_name=>asset_type_name} }
      end
    end

    def publish
      items_for_publishing = resolve_publish_params params[:publish]
      items_for_publishing << @asset unless items_for_publishing.include? @asset
      @notified_items = items_for_publishing.select{|i| !i.can_manage?}
      @published_items = items_for_publishing - @notified_items

      @problematic_items = @published_items.select{|item| !item.publish!}

      if Seek::Config.email_enabled && !@notified_items.empty?
        deliver_publishing_notifications @notified_items
      end

      @published_items = @published_items - @problematic_items

      respond_to do |format|
        flash.now[:notice]="Publishing complete"
        format.html { render :template=>"assets/publish/published" }
      end
    end

    def set_asset
      c = self.controller_name.downcase
      @asset = eval("@"+c.singularize)
    end

    def preview_permissions
      set_no_layout
      people_in_group = request_permission_summary
      respond_to do |format|
        format.html { render :template=>"layouts/preview_permissions", :locals => {:people_in_group => people_in_group}}
      end
    end

    def request_permission_summary
        #get sharing_scope and access_type
        sharing_scope = params["sharing_scope"].to_i
        access_type = params["access_type"].to_i
        project_id = params["project_id"].blank? ? nil : params["project_id"].to_i
        your_proj_access_type = params["project_access_type"].blank? ? nil : params["project_access_type"].to_i

        contributor_types = params["contributor_types"].blank? ? [] : ActiveSupport::JSON.decode(params["contributor_types"])
        new_permission_data = params["contributor_values"].blank? ? {} : ActiveSupport::JSON.decode(params["contributor_values"])

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
        if (params["use_whitelist"].to_i == 1)
          people_in_whitelist = get_people_in_FG(nil, true, nil)
          unless people_in_whitelist.blank?
            people_in_group['WhiteList'] |= people_in_whitelist
          end
        end
        #if blacklist/whitelist is used
        if (params["use_blacklist"].to_i == 1)
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
        filtered_people = filtered_people.reject{|person| person[0] == current_user.id}
        #sort people by name
        filtered_people = filtered_people.sort{|a,b| a[1] <=> b[1]}
        #group people by access_type
        grouped_people = filtered_people.group_by{|person| person[2]}
        #if public scope is chosen
        if (sharing_scope == Policy::EVERYONE)
          grouped_people[5] = access_type
        end
        #sort by key of the hash
        grouped_people = Hash[grouped_people.sort]

        return grouped_people
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


    private

    def deliver_publishing_notifications items_for_notification
      owners_items={}
      items_for_notification.each do |item|
        item.managers.each do |person|
          owners_items[person]||=[]
          owners_items[person] << item
        end
      end

      owners_items.keys.each do |owner|
        Mailer.deliver_request_publishing User.current_user.person,owner,owners_items[owner],base_host
      end
    end

    #returns an enumeration of assets, or ISA elements, for publishing based upon the parameters passed

    def resolve_publish_params param
      return [] if param.nil?

      assets = []

      param.keys.each do |asset_class|
        param[asset_class].keys.each do |id|
          assets << eval("#{asset_class}.find_by_id(#{id})")
        end
      end
      assets.compact.uniq
    end

  end
end