module PeopleHelper

  def person_list_item_extra_details? person
    !(person.projects.empty? and person.institutions.empty?)  
  end

  #tag for displaying an image if person that has no user associated - but is only displayed if the current user is an admin
  def no_user_for_admins_img person
    if (!person.user && current_user.is_admin?)
      return image_tag_for_key("no_user",nil,"No associated user",nil,"")
    end
  end

  def pal_icon person
    person.is_pal? ? image("pal",:alt=>"Pal",:title=>tooltip_title_attrib("Official #{Seek::ApplicationConfiguration.get_dm_project_name} Pal"), :style=>"vertical-align: middle")  : ""
  end

  def admin_icon person
    person.is_admin? ? image("admin",:alt=>"Admin",:title=>tooltip_title_attrib("#{Seek::ApplicationConfiguration.get_dm_project_name} Administrator"), :style=>"vertical-align: middle") : ""
  end

  def discipline_list person
    unless person.disciplines.empty?
      text=""
      person.disciplines.each do |d|
        text += link_to(h(d.title),people_path(:discipline_id=>d.id))
        text += ", " unless person.disciplines.last==d
      end
    else
      text="<span class='none_text'>None specified</span>"
    end
    return text
  end

  def role_list person
    unless person.roles.empty?
      text=""
      person.roles.each do |r|
        text += link_to(h(r.title),people_path(:role_id=>r.id))
        text += ", " unless person.roles.last==r
      end
    else
      text="<span class='none_text'>None specified</span>"
    end
    return text
  end
  
end
