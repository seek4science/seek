#lib/seek/annotation_common.rb

module Seek
  module AnnotationCommon
    include CommonSweepers

    def update_annotations_ajax
      entity=controller_name.singularize.camelize.constantize.find(params[:id])
      if entity.can_view?
        update_owned_annotations entity
        eval("@#{controller_name.singularize} = entity")
        render :update do |page|
          page.replace_html 'tags_box', :partial=>'assets/tags_box'
          page.replace_html 'sidebar_tag_cloud', :partial=>'gadgets/tag_cloud_gadget'
          page.visual_effect :highlight, 'tags_box'
          page.visual_effect :highlight, 'sidebar_tag_cloud'
        end
      else
        render :update do |page|
          #this is to prevent a missing template error. If permission is not allowed, then the entity is silently left unchanged
        end
      end
    end

    protected

    #Updates all annotations as the owner of the entity, using the parameters passed through the web interface Any tags that do not match those passed in are removed as a tagging for this item.
    #New tags are assigned to the owner, which defaults to the current user.
    def update_annotations entity, attr='tag', use_autocomplete = true, owner=User.current_user
      unless owner.nil?
        entity.tag_with_params params, attr, use_autocomplete
        expire_annotation_fragments
      end
      
    end

    #Updates tags for a given owner using the params passed through the tagging web interface. This just updates the tags for a given owner, which defaults
    #to the current user - it doesn't affect other peoples tags for that item.
    def update_owned_annotations entity, attr='tag', use_autocomplete = true, owner=User.current_user
      unless owner.nil?
        entity.tag_as_user_with_params params, attr, use_autocomplete
        expire_annotation_fragments
      end
    end
  end

end
