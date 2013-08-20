require 'tempfile'
require 'dot_generator'

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
      html.html_safe
    rescue Exception=>e
      "<div id='isa_svg' class='none_text'>Currently unable to display the graph for this item</div>".html_safe
    end

  end

  def embedded_isa_svg_for_publishing root_item,deep=true,selected_items=[],current_item=nil
    begin
      current_item||=root_item
      html = '<script src="/javascripts/svg/svg.js" data-path="/javascripts/svg/"></script>'
      html << "\n"
      svg = to_svg_for_publishing(root_item,deep,current_item,selected_items)
      unless  svg.blank?
        html << "<div id='isa_svg'><script type=\'image/svg+xml'>#{svg}</script></div>"
      end
      html.html_safe
    rescue Exception=>e
      "<div id='isa_svg' class='none_text'>Currently unable to display the graph for this item</div>".html_safe
    end

  end

  FILL_COLOURS = {'Sop'=>"cadetblue3",
                  'Model'=>"yellow3",
                  'DataFile'=>"#eec591",
                  'Investigation'=>"#C7E9C0",
                  'Study'=>"#91c98b",
                  'Assay'=>"#64b466",
                  'Publication'=>"#84B5FD",
                  'Presentation' => "cadetblue2",
                  'Sample' => "orange",
                  'Specimen' => "red"}

  FILL_COLOURS.default = "cadetblue"

  def buiding_elements root_item,deep=true,current_item=nil
    begin
      current_item||=root_item
      dot_elements = to_dot(root_item,deep,current_item)
      elements = dot_elements.split(';')
      edges = elements.select{|e| e.include?('--')}
      #FIXME:strip
      nodes = edges.collect{|edge| edge.split('--')}.flatten.uniq
      nodes = nodes.each{|n| n.strip!}
      hash_elements = {:elements => []}

      nodes.each do |node|
        item_type, item_id = node.split('_')
        item = item_type.constantize.find_by_id(item_id)
        hash_elements[:elements] << {:group => 'nodes',
                                     :data => {:id => node, :name => truncate(item.title) , :faveColor => FILL_COLOURS[item_type]}
                                    }
      end
      edges.each do |edge|
        #FIXME:strip
        source, target = edge.split('--')
        source.strip!
        target.strip!
        edge.strip!
        hash_elements[:elements] << {:group => 'edges',
                                     :data => {:id => edge, :source => source, :target => target, :faveColor => '#6FB1FC'}
        }
      end

      hash_elements[:elements]
    rescue Exception=>e
      "<div class='none_text'>Currently unable to display the graph for this item</div>".html_safe
    end
  end
  
end
