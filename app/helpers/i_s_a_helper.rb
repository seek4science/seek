require 'tempfile'

module ISAHelper
  
  NO_DELETE_EXPLANTIONS={Assay=>"You cannot delete an assay that has items associated with it.",
                         Study=>"You cannot delete a Study that has Assays associated with it.",
                         Investigation=>"You cannot delete an Investigation that has Studies associated with it." ,
                         Specimen=>"You cannot delete a #{Seek::Config.sample_parent_term} that has Samples associated with it.",
                         Sample=>"You cannot delete a Sample that has Assays associated with it."
  }
  
  include DotGenerator
  
  def delete_ISA_icon model_item, user
    item_name = model_item.class.name
    item_name = "Analysis" if (model_item.kind_of?(Assay) && model_item.is_modelling?)
    if model_item.can_delete?(user)
      return "<li>"+image_tag_for_key('destroy',url_for(model_item),"Delete #{item_name}", {:confirm=>"Are you sure?",:method=>:delete },"Delete #{item_name}") + "</li>"
    elsif !model_item.can_delete?(user) && model_item.can_edit?(user)
      explanation = unable_to_delete_text model_item
      return "<li><span class='disabled_icon disabled' onclick='javascript:alert(\"#{explanation}\")' title='#{tooltip_title_attrib(explanation)}' >"+image('destroy', {:alt=>"Delete",:class=>"disabled"}) + " Delete #{item_name} </span></li>"
    end
  end
  
  def unable_to_delete_text model_item
    associated = false
    case model_item.class
      when Assay
        associated = !(model_item.assets.empty? && model_item.related_publications.empty?)
      when Study
        associated = !model_item.assays.empty?
      when Investigation
        associated = !model_item.studies.empty?
      when Specimen
        associated = !model_item.sampes.empty?
      when Sample
        associated = !model_item.assays.empty?
      else

    end
    text =   associated==true ?  NO_DELETE_EXPLANTIONS[model_item.class] : "You are not authorized to delete this #{model_item.class.name}"
    return text
  end


  def embedded_isa_svg root_item,deep=true,current_item=nil
    begin
      current_item||=root_item
      html = '<script src="/javascripts/svg/svg.js" data-path="/javascripts/svg/"></script>'
      html << "\n"
      svg = to_svg(root_item,deep,current_item)
      unless  svg.blank?
        html << "<div id='isa_svg'><script type=\'image/svg+xml'>#{svg}</script></div>"
      end
      html
    rescue Exception=>e
      "<div id='isa_svg' class='none_text'>Currently unable to display the graph for this item</div>"
    end

  end
  
end
