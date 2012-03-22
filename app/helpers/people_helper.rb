module PeopleHelper

  def person_list_item_extra_details? person
    !(person.projects.empty? and person.institutions.empty?)  
  end

  #tag for displaying an image if person that has no user associated - but is only displayed if the current user is an admin
  def no_user_for_admins_img person
    if (!person.user && admin_logged_in?)
      return image_tag_for_key("no_user",nil,"No associated user",nil,"")
    end
  end

  def seek_role_icons person
    icons = ''
    person.roles.each do |role|
      icons << image("#{role}",:alt=>"#{role}",:title=>tooltip_title_attrib(role.humanize), :style=>"vertical-align: middle")
    end
    icons
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

  def project_role_list person
    unless person.project_roles.empty?
      text=""
      person.project_roles.each do |r|
        text += link_to(h(r.title),people_path(:project_role_id=>r.id))
        text += ", " unless person.project_roles.last==r
      end
    else
      text="<span class='none_text'>None specified</span>"
    end
    return text
  end
  
end
