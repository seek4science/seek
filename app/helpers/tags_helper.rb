module TagsHelper
  include ActsAsTaggableOn::TagsHelper
  include ActsAsTaggableOn
  include Annotations



  def popularity(annotations)
    popularity = []
    annotations.all.each do |x|
      popularity[x.value_id] += 1
    end
  end

  def tag_cloud(tags, classes,counter_method=:count)
    tags = tags.sort_by{|t| t.value.text.downcase}
    max_count = tags.max_by(&counter_method).send(counter_method).to_f
    if max_count < 1
      max_count = 1
    end


    tags.each do |tag|
      index = ((tag.send(counter_method) / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end


  def ann_cloud(tags, classes, counter_method=:count)
    tags = tags.sort_by{|t| t.value.text.downcase}

    max_count = 0

    tags.each do |tag|
      tag_count = tag.value.annotations.count
      max_count = tag_count if max_count < tag_count
    end

    tags.each do |tag|
      index = ((tag.value.annotations.count / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end


  def overall_tag_cloud(tags,classes,&block)
    ann_cloud(tags, classes, &block)
  end
  

  def tags_for_context context
    #Tag.find(:all).select{|t| !t.taggings.detect{|tg| tg.context==context.to_s}.nil? }
    Tag.find(:all,:group=>"tags.id",:joins=>:taggings,:conditions=>["taggings.context = ?",context.to_s])
  end

  def show_tag?(tag)
    #FIXME: not sure this is required or works any more. was originally to work around a bug in acts-as-taggable-on
    tag.taggings.size>1 || (tag.taggings.size==1 && tag.taggings[0].taggable_id)
  end

  def link_for_tag tag, options={}
    length=options[:truncate_length]
    length||=150
    link = show_tag_path(tag)
    link_to h(truncate(tag.name,:length=>length)), link, :class=>options[:class],:id=>options[:id],:style=>options[:style],:title=>tooltip_title_attrib(tag.name)
  end

  def link_for_ann tag, options={}
    length=options[:truncate_length]
    length||=150
    link = show_ann_path(tag)

    text = tag.value.text

    link_to h(truncate(text,:length=>length)), link, :class=>options[:class],:id=>options[:id],:style=>options[:style],:title=>tooltip_title_attrib(text)
  end


  def list_item_tags_list tags,options={}
    tags.map do |t|
      divider=tags.last==t ? "" : "<span class='spacer'>,</span> ".html_safe
      link_for_ann(t,options)+divider
    end
  end

  def aggregated_asset_tags
    tags = []
    (asset_model_classes | [Assay]).each do |c|
      tags |= c.tag_counts if c.taggable?
      aggregated_asset_annotations |= Annotation.find(:all, :conditions => "annotatable_type = '#{c.class}' AND annotatable_id = '#{c.id}'")
    end
    tags
  end

  #defines the tag box, with AJAX tag entry and removal
  def item_tags_and_tag_entry
    #only show the tag box if a user is logged in
    return unless current_user
    %!<div id="tags_box" class="contribution_section_box">
      #{render :partial=>"assets/tags_box", :no_tags_message=>"Add tags (comma separated) ..."}
    </div>!
  end

end
