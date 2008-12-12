module PeopleHelper
  
  def person_list_item_extra_details? person
    !(person.projects.empty? and person.institutions.empty?)  
  end



  def list_item_tags_list tags
    tags.map do |t|
      divider=tags.last==t ? "" : "&nbsp;&nbsp;|&nbsp;&nbsp;"
      link_to(h(t.name),"http://www.google.com")+divider
    end
  end

  
  
end
