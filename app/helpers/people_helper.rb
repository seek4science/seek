module PeopleHelper
  
  def item_list items
    str=""
    items.each {|ins| str=str+ins.name+" "}
    return str
  end
end
