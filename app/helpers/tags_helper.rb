module TagsHelper

  include Annotations

  def ann_cloud(tags, classes, counter_method=:count)
    tags = tags.sort_by{|t| t.text.downcase}

    max_count = tags.max_by(&:tag_count).tag_count.to_f
    if max_count < 1
      max_count = 1
    end

    tags.each do |tag|
      index = ((tag.tag_count / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end

  def fetch_tags_for_item object,attribute="tag"
    all_tags = TextValue.all_tags attribute
    item_tags = object.annotations.with_attribute_name(attribute).include_values.collect{|a| a.value}.uniq

    return all_tags,item_tags
  end

  def link_for_ann tag, options={}
    length=options[:truncate_length]
    length||=150
    link = show_ann_path(tag)

    text = tag.text

    link_to truncate(text,:length=>length), link, :class=>options[:class],:id=>options[:id],:style=>options[:style],
            'data-tooltip' => tooltip(text)
  end

  def list_item_tags_list tags,options={}
    tags.map do |t|
      divider=tags.last==t ? "" : "<span class='spacer'>,</span> ".html_safe
      link_for_ann(t,options)+divider
    end.join("").html_safe
  end

  def refresh_tag_cloud(entity, page)
    page.replace 'tag_cloud', :partial => 'tags/tag_cloud',
                 :locals => {:tags => fetch_tags_for_item(entity)[1],
                             :show_overall_count => false,
                             :id => "tag_cloud",
                             :tags_smaller => true,
                             :no_tags_text => "This item has not yet been tagged."}
  end

  #determines whether the tag cloud should be immediately updated, dependent on the number of tags. A large number of tags can make rebuilding it
  #an expensive process on the next page reload. The limit is based upon the number of visible tags set in the configuration
  def immediately_clear_tag_cloud?
    Annotation.count < (Seek::Config.max_visible_tags * 2)
  end

  # The tag cloud is generation is quite an expensive process and doesn't need to automatically update when filled up already.
  # When it is small its nice to see new tags appear in the cloud.
  def handle_clearing_tag_cloud(page)
    if immediately_clear_tag_cloud?
      page.replace_html 'sidebar_tag_cloud', :partial => 'gadgets/tag_cloud_gadget'
    else
      RebuildTagCloudsJob.new.queue_job
    end
  end

end
