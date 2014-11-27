module ScalesHelper

  def all_scaled_items_hash
    #key: item_type, value: items
    resource_hash = {}
    all_scaled_assets = Scale.all.collect do |scale|
      scale.assets
    end.flatten.uniq

    all_scaled_assets.group_by { |asset| asset.class.name }.each do |asset_type, items|
      resource_hash[asset_type] = items if items.count > 0
    end

    resource_hash

  end

  def all_items_hash
    #key: item_type, value: items
    resource_hash = {}
    Seek::Util.user_creatable_types.each do |klass|
      items = klass.all
      resource_hash["#{klass}"] = items if items.count > 0
    end
    resource_hash
  end

  def show_scales?
    Scale.count > 0
  end


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
          link = link_to(scale.title, scale)
          link_with_params = model.fetch_additional_scale_info(scale.id).collect do |info|
          param = content_tag(:em, info["param"])
          unit = content_tag(:em, info["unit"])
          "#{link} (param:#{param} unit:#{unit})"
          end
          link_with_params.empty?? link : link_with_params
        end.flatten
        links = join_with_and(links)
        links.html_safe
      else
        content_tag (:ul), :class => "model_scales_list" do
          scales.collect do |scale|
            link = link_to(scale.title, scale)
            link_with_params = model.fetch_additional_scale_info(scale.id).collect do |info|
              param = content_tag(:em, info["param"])
              unit = content_tag(:em, info["unit"])
              line = "for scale #{link} passes #{param} with unit of #{unit}"
              concat(content_tag(:li, line.html_safe))
            end
             concat(content_tag(:li, link.html_safe)) if link_with_params.empty?
          end
        end
      end
    end
  end

  def scales_list_for_list_item entity
    if entity.respond_to?(:scales) && show_scales?
      render :partial=>"scales/asset_scales_list",:object=>entity, :locals=>{:list_item=>true}
    else
      ""
    end
  end

end
