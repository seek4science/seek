module TagsHelper
  include Annotations

  def ann_cloud(tags, classes, _counter_method = :count)
    tags = tags.sort_by { |t| t.text.downcase }

    max_count = tags.max_by(&:tag_count).tag_count.to_f
    max_count = 1 if max_count < 1

    tags.each do |tag|
      index = ((tag.tag_count / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end

  def fetch_tags_for_item(object, attribute = 'tag')
    all_tags = TextValue.all_tags attribute
    item_tags = object.annotations.with_attribute_name(attribute).include_values.collect(&:value).uniq

    [all_tags, item_tags]
  end

  def fetch_tags_for_item_owned_by_current_user (object)
    current_user ? object.annotations.with_attribute_name("tag").by_source("User", User.current_user.id).collect { |a| a.value }.uniq : []
  end

  def link_for_ann(tag, options = {})
    length = options[:truncate_length]
    length ||= 150
    link = show_ann_path(tag, type: options[:type])

    text = tag.text
    tooltip = text.length > length ? text : nil
    link_to truncate(text, length: length), link, :class => options[:class], :id => options[:id], :style => options[:style], 'data-tooltip' => tooltip
  end

  def list_item_tags_list(tags, options = {})
    return content_tag(:span, class: 'none_text') { options[:blank] || 'Not specified' } if tags.blank?
    tags.map do |t|
      divider = tags.last == t ? '' : "<span class='spacer'>,</span> ".html_safe
      link_for_ann(t, options) + divider
    end.join('').html_safe
  end

  # defined tags with a count above or equal to the configured threshold
  def tags_above_threshold
    TextValue.all_tags.select { |tag| tag.tag_count >= Seek::Config.tag_threshold }
  end

  # determines whether the tag cloud should be immediately updated, dependent on the number of tags. A large number of tags can make rebuilding it
  # an expensive process on the next page reload. The limit is based upon the number of visible tags set in the configuration
  def immediately_clear_tag_cloud?
    Annotation.count < (Seek::Config.max_visible_tags * 2)
  end
end
