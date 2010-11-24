require 'tempfile'

module ISAHelper
  
  NO_DELETE_EXPLANTIONS={Assay=>"You cannot delete an assay that has items associated with it.",Study=>"You cannot delete a Study that has Assays associated with it.",Investigation=>"You cannot delete an Investigation that has Studies associated with it."}
  
  include DotGenerator
  
  def delete_ISA_icon model_item, user
    item_name = model_item.class.name
    item_name = "Analysis" if (model_item.kind_of?(Assay) && model_item.is_modelling?)
    if model_item.can_delete?(user)
      return "<li>"+image_tag_for_key('destroy',url_for(model_item),"Delete #{item_name}", {:confirm=>"Are you sure?",:method=>:delete },"Delete #{item_name}") + "</li>"
    elsif !model_item.can_delete?(user) && model_item.can_edit?(user)
      explanation=unable_to_delete_text model_item
      return "<li><span class='disabled_icon disabled' onclick='javascript:alert(\"#{explanation}\")' title='#{tooltip_title_attrib(explanation)}' >"+image('destroy', {:alt=>"Delete",:class=>"disabled"}) + " Delete #{item_name} </span></li>"
    end
  end
  
  def unable_to_delete_text model_item
    text=NO_DELETE_EXPLANTIONS[model_item.class] || "You are unable to delete this #{model_item.class.name}"
    return text
  end
  
  def embedded_isa_svg root_item,deep=true,current_item=nil    
    current_item||=root_item
    "<div id='isa_svg'><script type=\'image/svg+xml'>#{to_svg(root_item,deep,current_item)}</script></div>"
  end
  
end
