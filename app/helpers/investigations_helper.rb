module InvestigationsHelper
  
  def investigation_link investigation
    unless investigation.nil?
      link_to h(investigation.title),investigation
    else
      "<span class='none_text'>Not associated with an Investigation</span>".html_safe
    end
  end

end
