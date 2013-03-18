require 'tempfile'

module ISAHelper

  include DotGenerator
  
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
