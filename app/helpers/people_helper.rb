module PeopleHelper
  
  def person_list_item_extra_details? person
    !(person.projects.empty? and person.institutions.empty?)  
  end



  def list_item_tools_list tools
    tools.map do |t|
      divider=tools.last==t ? "" : "&nbsp;&nbsp;|&nbsp;&nbsp;"
      link_to(h(t.name),"http://www.google.com")+divider
    end
  end

  
  
end
