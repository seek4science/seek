# lib/seek/annotation_common.rb

module Seek
  module AnnotationCommon
    include CommonSweepers
    include TagsHelper

    def update_annotations_ajax
      entity = controller_name.classify.constantize.find(params[:id])
      if entity.can_view?
        update_owned_annotations(entity, current_user, 'tag', params[:tag_list])
        eval("@#{controller_name.singularize} = entity")
        render :update do |page|
          refresh_tag_cloud(entity, page)

          handle_clearing_tag_cloud(page)

          page.visual_effect :highlight, 'tag_cloud'
          page.visual_effect :highlight, 'sidebar_tag_cloud'
        end
      else
        render nothing: true, status: 400
      end
    end

    protected

    def update_scales(entity)
      scale_ids = params[:scale_ids]
      return if entity.new_record? && !entity.save
      entity.scales = scale_ids
      update_scales_with_params entity unless params[:scale_ids_and_params].nil?
    end

    def update_scales_with_params(entity)
      params[:scale_ids_and_params].each do |json|
        json = JSON.parse(json)
        entity.attach_additional_scale_info json['scale_id'], param: json['param'], unit: json['unit']
      end
    end

    # Updates all annotations as the owner of the entity, using the parameters passed through the web interface Any tags that do not match those passed in are removed as a tagging for this item.
    # New tags are assigned to the owner, which defaults to the current user.
    def update_annotations(param, entity, attr = 'tag', owner = User.current_user)
      unless owner.nil?
        entity.tag_annotations(param, attr)
        if immediately_clear_tag_cloud?
          expire_annotation_fragments(attr)
        else
          RebuildTagCloudsJob.new.queue_job
        end
      end
    end

    # Updates tags for a given owner using the params passed through the tagging web interface. This just updates the tags for a given owner, which defaults
    # to the current user - it doesn't affect other peoples tags for that item.
    def update_owned_annotations(entity, owner, attr, annotations)
      unless owner.nil?
        entity.tag_annotations_as_user(annotations, attr, owner)
        expire_annotation_fragments(attr) if immediately_clear_tag_cloud?
      end
    end
  end
end
