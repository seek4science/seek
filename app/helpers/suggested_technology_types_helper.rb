module SuggestedTechnologyTypesHelper
  def create_suggested_technology_type_popup_link  link_from="technology_types"
        return link_to_remote_redbox(image("new") + ' new technology type',
         { :url => new_popup_suggested_technology_types_path,
           :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
           :with => "'link_from=#{link_from}'",


         }
    )
    end
end
