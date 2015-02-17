#lib/seek/annotation_common.rb

module Seek
  module AnnotationCommon
    include CommonSweepers

    #determines whether the tag cloud should be immediately updated, dependent on the number of tags. A large number of tags can make rebuilding it
    #an expensive process on the next page reload. The limit is based upon the number of visible tags set in the configuration
    def immediately_clear_tag_cloud?
      Annotation.count < (Seek::Config.max_visible_tags * 2)
    end

    def update_annotations_ajax
      entity=controller_name.singularize.camelize.constantize.find(params[:id])
      if entity.can_view?
        clear_cloud = immediately_clear_tag_cloud?
        update_owned_annotations(entity, current_user, 'tag', params[:tag_list])
        eval("@#{controller_name.singularize} = entity")
        render :update do |page|
          page.replace 'tag_cloud', :partial=>'tags/tag_cloud',
                       :locals=>{:tags=>fetch_tags_for_item(entity)[1],
                                 :show_overall_count=>false,
                                 :id=>"tag_cloud",
                                 :tags_smaller=>true,
                                 :no_tags_text=>"This item has not yet been tagged."}

          # The tag cloud is generation is quite an expensive process and doesn't need to automatically update when filled up already.
          # When it is small its nice to see new tags appear in the cloud.
          if clear_cloud
            page.replace_html 'sidebar_tag_cloud', :partial=>'gadgets/tag_cloud_gadget'
          else
            RebuildTagCloudsJob.create_job
          end

          page.visual_effect :highlight, 'tags_box'
          page.visual_effect :highlight, 'sidebar_tag_cloud'
        end
      else
        render :nothing => true, :status => 400
      end
    end

    protected

    def update_scales entity
      scale_ids = params[:scale_ids]
      return if entity.new_record? && !entity.save
      entity.scales=scale_ids
      unless (params[:scale_ids_and_params].nil?)
        update_scales_with_params entity
      end
    end

    def update_scales_with_params entity

      params[:scale_ids_and_params].each do |json|
        json = JSON.parse(json)
        entity.attach_additional_scale_info json["scale_id"], :param=>json["param"],:unit=>json["unit"]
      end
    end

    #Updates all annotations as the owner of the entity, using the parameters passed through the web interface Any tags that do not match those passed in are removed as a tagging for this item.
    #New tags are assigned to the owner, which defaults to the current user.
    def update_annotations entity, attr='tag', owner=User.current_user
      unless owner.nil?
        entity.tag_with_params params, attr
        if immediately_clear_tag_cloud?
          expire_annotation_fragments(attr)
        else
          RebuildTagCloudsJob.create_job
        end
      end
      
    end

    #Updates tags for a given owner using the params passed through the tagging web interface. This just updates the tags for a given owner, which defaults
    #to the current user - it doesn't affect other peoples tags for that item.
    def update_owned_annotations(entity, owner, attr, annotations)
      unless owner.nil?
        entity.tag_annotations_as_user(annotations, attr, owner)
        if immediately_clear_tag_cloud?
          expire_annotation_fragments(attr)
        else
          #TODO: should expire and rebuild in a background task
        end
      end
    end
  end

end
