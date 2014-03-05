module TechnologyTypesHelper

  def create_technology_type_popup_link controller_name="technology_types"
        return link_to_remote_redbox(image("new") + ' new technology type',
         { :url => new_technology_type_path ,
           :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
           :with => "'link_from=#{controller_name}'"
         }
    )
    end

  def link_to_technology_type assay
    uri = assay.technology_type.term_uri
    label = assay.technology_type.label
    if assay.valid_technology_type_uri?
      link_to label,technology_types_path(:uri=>uri,:label=>label)
    else
      label
    end
  end

  def parent_technology_types_list_links parents
    unless parents.empty?
      parents.collect do |par|
        link_to par.label,technology_types_path(uri: par.term_uri,label: par.label),:class=>"parent_term"
      end.join(" | ").html_safe
    else
      content_tag :span,"No parent terms",:class=>"none_text"
    end
  end

  def child_technology_types_list_links children
    child_type_links children,"technology_type"
  end

end
