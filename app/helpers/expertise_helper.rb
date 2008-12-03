module ExpertiseHelper
  def list_item_expertise_list expertise  
    expertise.map do |e|
      divider=expertise.last==e ? "" : " | "
      link_to(h(e.name),url_for(e))+divider
    end
  end
end
