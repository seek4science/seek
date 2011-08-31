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

      existing_anns = [] # entity.annotations_with_attribute_and_by_source("tag", owner) #get_annotations_owned_by(owner, entity)
      entity_annotations = Annotation.all.select { |x| x.annotatable == entity }

      owner_tags = Annotation.all.select { |ann| ann.source_id == current_user.id }

      new_annotations = params[:tag_autocompleter_unrecognized_items] || []
      known_annotation_ids = params[:tag_autocompleter_selected_ids] || []
      known_annotations = known_annotation_ids.collect{ |id| Annotation.find(id) }

      anns_to_keep = []
      new_names = []

      known_annotations.each do |ann|
        if !ann.nil?
          new_names << ann.value.text unless ann.nil? || (existing_anns.include?(ann) && !owner_tags.include(ann))
          anns_to_keep << ann if existing_anns.include?(ann)
        end
      end



      entity_annotations.each do |existing_ann| #for each existing annotation
        unless known_annotations.include? existing_ann #unless we're keeping it
          existing_ann.delete #delete it.
        end
      end

      save_failed = false

      new_annotations.each do |ann|
        @annotation = Annotation.new(:source => current_user,
                                     :annotatable => entity,
                                     :attribute_name => "tag",
                                     :value => ann)
        if !@annotation.save
          save_failed = true
        end
      end
      return save_failed
    end

    #Updates tags for a given owner using the params passed through the tagging web interface. This just updates the tags for a given owner, which defaults
    #to the current user - it doesn't affect other peoples tags for that item.
    def update_owned_annotations entity, owner=current_user


      new_annotations = params[:tag_autocompleter_unrecognized_items] || []
      known_annotation_ids=params[:tag_autocompleter_selected_ids] || []
      known_annotations = known_annotation_ids.collect { |id| Annotation.find(id) }

      new_annotations, known_annotations = check_if_new_annotations_are_known new_annotations, known_annotations

      annotations = []
      known_annotations.each do |ann|
        annotations << ann unless ann.nil?
      end unless known_annotation_ids.nil?

      new_annotations.each do |ann|
        annotations << ann
      end


      entity_annotations = Annotation.find(:all, :conditions => "annotatable_id = '#{entity.id}' AND annotatable_type = '#{entity.type}'")

      entity_annotations.each do |existing_ann|     #Delete all annotations for this entity that
        unless annotations.include? existing_ann  #are no longer on the list
          existing_ann.delete
        end
      end

      save_successful = true

      new_annotations.each do |ann|
          @annotation = Annotation.new(:source => owner,
                                       :annotatable => entity,
                                       :attribute_name => "tag",
                                       :value => ann)
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
         fixed_new_tags = []
        new_annotations.each do |new_ann|
          ann=Annotation.find(:all, :conditions => "value_id = '#{new_ann.value_id}'")
          if ann.nil?
            fixed_new_tags << new_ann
          else
            known_annotations << ann unless known_annotations.include?(ann)
          end
        end
        return new_annotations, known_annotations
      end
    end
  end
