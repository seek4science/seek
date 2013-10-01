module ScalesHelper

  def show_scales?
    Scale.count>0
  end

  def scales_list entity
    scales = entity.scales
    links = scales.collect do |scale|
      title = scale.title
      info = entity.fetch_additional_scale_info(scale.id)

      link = link_to title, scale
      link << " (param:#{info["param"]} unit:#{info["unit"]})" unless info.nil?
      link
    end
    links = join_with_and(links)
    links = text_or_not_specified("") if links.blank?
    links.html_safe

  end

  def scales_list_for_list_item entity
    if show_scales?
      render :partial=>"scales/asset_scales_list",:object=>entity, :locals=>{:list_item=>true}
    else
      ""
    end
  end
end
