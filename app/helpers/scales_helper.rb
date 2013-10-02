module ScalesHelper

  def show_scales?
    Scale.count>0
  end

  def scales_list entity,list_item=false
    scales = entity.scales
    if entity.is_a?(Model)  #model scales are displayed slightly differently due to the params
      model_scales_list entity, list_item
    else
      links = scales.collect do |scale|
        title = scale.title
        link_to title,scale
      end
      links = join_with_and(links)
      links = text_or_not_specified("") if links.blank?
      links.html_safe
    end
  end

  def model_scales_list model, list_item
    scales = model.scales
    if scales.empty?
      text_or_not_specified("")
    else
      if list_item
        links = scales.collect do |scale|
          model.fetch_additional_scale_info(scale.id).collect do |info|

          link = link_to(scale.title, scale)
          param = content_tag(:em, info["param"])
          unit = content_tag(:em, info["unit"])
          "#{link}(param:#{param} unit:#{unit})"
          end
        end.flatten
        links = join_with_and(links)
        links.html_safe
      else
        content_tag (:ul), :class => "model_scales_list" do
          scales.collect do |scale|
            model.fetch_additional_scale_info(scale.id).collect do |info|
              link = link_to(scale.title, scale)
              param = content_tag(:em, info["param"])
              unit = content_tag(:em, info["unit"])
              line = "for scale #{link} passes #{param} with unit of #{unit}"
              concat(content_tag(:li, line.html_safe))
            end
          end
        end
      end
    end
  end

  def scales_list_for_list_item entity
    if show_scales?
      render :partial=>"scales/asset_scales_list",:object=>entity, :locals=>{:list_item=>true}
    else
      ""
    end
  end
end
