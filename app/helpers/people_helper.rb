module PeopleHelper
  
  def person_list_item_extra_details? person
    !(person.projects.empty? and person.institutions.empty?)  
  end

  #tag for displaying an image if person that has no user associated - but is only displayed if the current user is an admin
  def no_user_for_admins_img person
    if (!person.user && current_user.is_admin?)
      return icon("no_user",nil,"No associated user",nil,"")
    end
  end

  def discipline_list person
    unless person.disciplines.empty?
      text=""
      person.disciplines.each do |d|
        text += link_to(h(d.title),people_path(:discipline_id=>d.id))
        text += ", " unless person.disciplines.last==d
      end
    else
      text="<span class='none_text'>Not known</span>"
    end
    return text
  end
  
end
