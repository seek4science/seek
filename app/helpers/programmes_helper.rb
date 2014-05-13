module ProgrammesHelper

  def list_item_programme_attribute(project)
    html = content_tag :p,:class=>"list_item_attribute" do
      label = content_tag :b do
        t('programme')

      end
      label + ": " + programme_link(project)

    end
    html.html_safe
  end

end
