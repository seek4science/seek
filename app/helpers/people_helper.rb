module PeopleHelper
  
  def person_list_item_extra_details? person
    !(person.projects.empty? and person.institutions.empty?)  
  end


  def link_for_tag tag, options={}
      link=people_url
      if (options[:type]==:expertise)
        link=people_url(:expertise=>tag.name)
      end
      if (options[:type]==:tools)
        link=people_url(:tools=>tag.name)
      end
      link_to h(tag.name), link, :class=>options[:class]
  end

  def list_item_tags_list tags,options={}
    tags.map do |t|
      divider=tags.last==t ? "" : "&nbsp;&nbsp;|&nbsp;&nbsp;"
      link_for_tag(t,options)+divider
    end
  end

  #tag for displaying an image if person that has no user associated - but is only displayed if the current user is an admin
  def no_user_for_admins_img person
    if (!person.user && current_user.is_admin?)
      return icon("no_user",nil,"No associated user",nil,"")
    end
  end

  
  
end
