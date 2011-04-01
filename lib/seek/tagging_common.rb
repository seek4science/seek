module Seek

  module TaggingCommon

    include CommonSweepers

    def update_tags_ajax
      entity=controller_name.singularize.camelize.constantize.find(params[:id])
      if entity.can_view?
        update_owned_tags entity

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

    #Updates all tags as the owner of the entity, using the parameters passed through the web interface Any tags that do not match those passed in are removed as a tagging for this item.
    #New tags are assigned to the owner, which defaults to the current user.
    def update_tags entity, owner=current_user

      existing_tags = entity.tag_counts
      owner_tags = entity.owner_tags_on(owner, :tags)

      new_tags = params[:tag_autocompleter_unrecognized_items] || []
      known_tag_ids =params[:tag_autocompleter_selected_ids] || []
      known_tags = known_tag_ids.collect { |id| ActsAsTaggableOn::Tag.find(id) }

      new_tags, known_tags = check_if_new_tags_are_known new_tags, known_tags

      new_names =[]
      tags_to_keep=[]
      known_tags.each do |tag|
        new_names << tag.name unless tag.nil? || (existing_tags.include?(tag) && !owner_tags.include?(tag))
        tags_to_keep << tag if existing_tags.include?(tag)
      end unless known_tag_ids.nil?

      #remove unmatched tags
      existing_tags.each do |existing_tag|
        unless tags_to_keep.include? existing_tag
          existing_tag.taggings.each do |tagging|
            if tagging.taggable == entity
              tagging.delete
            end
          end
        end
      end

      new_tags.each do |tag|
        new_names << tag
      end

      owner.tag entity, :with=>new_names.join(","), :on=>:tags

      expire_tag_fragments

    end

    #Updates tags for a given owner using the params passed through the tagging web interface. This just updates the tags for a given owner, which defaults
    #to the current user - it doesn't affect other peoples tags for that item.
    def update_owned_tags entity, owner=current_user
      new_tags = params[:tag_autocompleter_unrecognized_items] || []
      known_tag_ids=params[:tag_autocompleter_selected_ids] || []
      known_tags = known_tag_ids.collect { |id| ActsAsTaggableOn::Tag.find(id) }

      new_tags, known_tags = check_if_new_tags_are_known new_tags, known_tags

      tags =""
      known_tags.each do |tag|
        tags << tag.name << "," unless tag.nil?
      end unless known_tag_ids.nil?

      new_tags.each do |tag|
        tags << tag << ","
      end

      owner.tag entity, :with=>tags, :on=>:tags

      expire_tag_fragments

    end
   

    #double checks and resolves if any new tags are actually known. This can occur when the tag has been typed completely rather than
    #relying on autocomplete. If not fixed, this could have an impact on preserving tag ownership.
    def check_if_new_tags_are_known new_tags, known_tags
      fixed_new_tags = []
      new_tags.each do |new_tag|
        tag=ActsAsTaggableOn::Tag.find_by_name(new_tag.strip)
        if tag.nil?
          fixed_new_tags << new_tag
        else
          known_tags << tag unless known_tags.include?(tag)
        end
      end
      return new_tags, known_tags
    end


  end

end