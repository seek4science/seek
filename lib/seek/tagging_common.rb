module Seek

  module TaggingCommon

    def update_tags_ajax
          
    entity=controller_name.singularize.camelize.constantize.find(params[:id])
    update_tags entity

    eval("@#{controller_name.singularize} = entity")

    render :update do |page|
      page.replace_html 'tags_box',:partial=>'assets/tags_box'
      page.replace_html 'sidebar_tag_cloud',:partial=>'gadgets/merged_tag_cloud_gadget'
      page.visual_effect :highlight,'tags_box'
      page.visual_effect :highlight,'sidebar_tag_cloud'
    end
  end

  protected

  def update_tags entity
    new_tags = params[:tag_autocompleter_unrecognized_items] || []
    known_tag_ids=params[:tag_autocompleter_selected_ids] || []

    tags=""
    known_tag_ids.each do |id|
      tag=ActsAsTaggableOn::Tag.find(id)
      tags << tag.name << "," unless tag.nil?
    end unless known_tag_ids.nil?

    new_tags.each do |tag|
      tags << tag << ","
    end

    current_user.tag entity,:with=>tags,:on=>:tags

  end

  end
end