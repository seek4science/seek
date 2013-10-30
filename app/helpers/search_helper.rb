require 'seek/external_search'

module SearchHelper
  include Seek::ExternalSearch
  def search_type_options
    search_type_options = ["All", "Institutions", "People", "Projects"]
    search_type_options |= Seek::Util.user_creatable_types.collect{|c| [(c.name.underscore.humanize == "Sop" ? t('sop') : c.name.underscore.humanize.pluralize),c.name.underscore.pluralize] }
    return search_type_options
  end
    
  def saved_search_image_tag saved_search
    tiny_image = image_tag "famfamfam_silk/find.png", :style => "padding: 11px; border:1px solid #CCBB99;background-color:#FFFFFF;"
    return link_to_draggable(tiny_image, saved_search_path(saved_search.id), :title=>tooltip_title_attrib("Search: #{saved_search.search_query} (#{saved_search.search_type})"),:class=>"saved_search", :id=>"sav_#{saved_search.id}")
  end

  def external_search_tooltip_text

    text = "Checking this box allows external resources to be includes in the search.<br/>"
    text << "External resources include: "
    text << search_adaptor_names.collect{|name| "<b>#{name}</b>"}.join(",")
    text << "<br/>"
    text << "This means the search will take longer, but will include results from other sites"
    text.html_safe
  end
end
