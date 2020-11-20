# lib/seek/annotation_common.rb

module Seek
  module AnnotationCommon
    include CommonSweepers
    include TagsHelper

    def update_annotations_ajax
      entity = controller_model.find(params[:id])
      if entity.can_view?
        update_owned_annotations(entity, current_user, 'tag', params[:tag_list])
        if entity.save
          instance_variable_set("@#{controller_name.singularize}", entity)
          @entity = entity
          respond_to do |format|
            format.js { render template: 'assets/update_annotations'}
          end
        else
          head :bad_request
        end
      else
        head :bad_request
      end
    end

    protected

    # Updates all annotations as the owner of the entity, using the parameters passed through the web interface Any tags that do not match those passed in are removed as a tagging for this item.
    # New tags are assigned to the owner, which defaults to the current user.
    def update_annotations(param, entity, attr = 'tag', owner = User.current_user)
      unless owner.nil?
        entity.add_annotations(param, attr)
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
        entity.add_annotations(annotations, attr, owner, true)
        expire_annotation_fragments(attr) if immediately_clear_tag_cloud?
      end
    end
  end
end
