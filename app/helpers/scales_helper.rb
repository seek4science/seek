module ScalesHelper

  def show_scales
    Scale.count>0
  end

  def scales_list scales
    links = scales.collect{|scale| link_to scale.title,scale}
    links = join_with_and(links)
    links = text_or_not_specified("") if links.blank?
    links.html_safe

  end
end
