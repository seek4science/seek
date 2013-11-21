module ScalesHelper

  def link_for_scale scale, options={}
    length=options[:truncate_length]
    length||=150
    link = scale_path(scale)
    link_to h(truncate(scale.name, :length=>length)), link, :class=>options[:class], :id=>options[:id], :style=>options[:style], :title=>tooltip_title_attrib(scale.name)
  end

  def sort_scales scales
    ordered_scales = scales.sort_by{|scale|
      Seek::Config.scales.index(scale.title)
    }
    ordered_scales
  end
  def show_item_scales resource
    link = ""
    ordered_scales =  sort_scales resource.scales
    ordered_scales.each do |scale|
      link += link_to h(scale.title), scale
      link += ",<br/>" unless scale==ordered_scales.last
    end
    link
  end

end
