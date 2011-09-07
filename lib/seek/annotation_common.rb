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
          page.replace_html 'sidebar_tag_cloud', :partial=>'gadgets/merged_tag_cloud_gadget'
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
    def update_annotations entity, owner=current_user

      return false if owner.nil?

      attr="tag"

      #FIXME: this is currently more or less a copy of Person.update_annotations - need consolidating

#      new_annotations = params[:tag_autocompleter_unrecognized_items] || []
#      known_annotation_ids=params[:tag_autocompleter_selected_ids] || []
#      known_annotations = known_annotation_ids.collect { |id| Annotation.find(id) }

      tags=[]
      params[:tag_autocompleter_selected_ids].each do |selected_id|
        tag=Annotation.find(selected_id)
        tags << tag.value.text
      end unless params[:tag_autocompleter_selected_ids].nil?
      params[:tag_autocompleter_unrecognized_items].each do |item|
        tags << item
      end unless params[:tag_autocompleter_unrecognized_items].nil?

      current = entity.annotations_with_attribute(attr)
      for_removal = []
      current.each do |cur|
        unless tags.include?(cur.value.text)
          for_removal << cur
        end
      end

      tags.each do |tag|
        exists = TextValue.find(:first,:conditions=>{:text=>tag})
        if exists
          if exists.annotations.select{|a| a.annotatable==entity && a.attribute.name==attr}.empty?
            annotation = Annotation.new(:source => owner,
                           :annotatable => entity,
                           :attribute_name => attr,
                           :value => exists)
            annotation.save!
          end
        else
          annotation = Annotation.new(:source => owner,
                         :annotatable => entity,
                         :attribute_name => attr,
                         :value => tag)
          annotation.save!
        end
      end
      for_removal.each do |annotation|
        annotation.destroy
      end
    end

    #Updates tags for a given owner using the params passed through the tagging web interface. This just updates the tags for a given owner, which defaults
    #to the current user - it doesn't affect other peoples tags for that item.
    def update_owned_annotations entity, owner=current_user


      new_annotations = params[:tag_autocompleter_unrecognized_items] || []
      known_annotation_ids=params[:tag_autocompleter_selected_ids] || []
      known_annotations = known_annotation_ids.collect { |id| Annotation.find(id) }

      annotations = []
      save_successful = true

      #all annotations for this entity object
      entity_annotations = entity.annotations

      new_annotations, known_annotations = check_if_new_annotations_are_known new_annotations, known_annotations

      #delete any annotations that have been removed from the list
      entity_annotations.each do |existing_ann|
        if !known_annotations.include?(existing_ann)
          existing_ann.delete #been deleted from the list
        end
      end

      #If we have any annotations that already exist,
      Annotation.all.each do |existing_ann|
        if !known_annotations.include?existing_ann
          @annotation = Annotation.new(:source => current_user, :annotatable => entity, :attribute_name => "tag", :value => existing_ann.value)
          if @annotation.save
            save_successful = true
          end
        end
      end

      #create new annotations for the new annotations and create new annotations for the existing ones
      new_annotations.each do |ann|
          @annotation = Annotation.new(:source => current_user,
                                       :annotatable => entity,
                                       :attribute_name => "tag",
                                       :value => ann)
          @annotation.save
          if !@annotation.save
            save_successful= false
          end
      end


        expire_annotation_fragments

        return save_successful

      end

      #double checks and resolves if any new tags are actually known. This can occur when the tag has been typed completely rather than
      #relying on autocomplete. If not fixed, this could have an impact on preserving tag ownership.
      def check_if_new_annotations_are_known new_annotations, known_annotations


        if !new_annotations.empty?
            Annotation.all.each do |old_ann|
              new_annotations.each{ |x| known_annotations << old_ann if x == old_ann.value.text}
            end
        end

        return new_annotations, known_annotations
      end


    end#annotationhelper
  end#seek
