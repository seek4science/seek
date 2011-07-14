module SearchHelper
  
  def search_type_options
    types = ["All","People","Institutions","Projects","Sops","Studies","Assays","Samples","Specimens","Investigations","Models","Data files", "Publications"]
    types.delete("Samples") unless Seek::Config.is_virtualliver
    types.delete("Specimens") unless Seek::Config.is_virtualliver
    types
  end
    
  def saved_search_image_tag saved_search
    tiny_image = image_tag "/images/famfamfam_silk/find.png", :style => "padding: 11px; border:1px solid #CCBB99;background-color:#FFFFFF;"
    return link_to_draggable(tiny_image, saved_search_path(saved_search.id), :title=>tooltip_title_attrib("Search: #{saved_search.search_query} (#{saved_search.search_type})"),:class=>"saved_search", :id=>"sav_#{saved_search.id}")
  end  
end
