module Seek
  module Taggable

    def tag_as_user_with_params params,attr="tag",use_autocomplete = true,owner=User.current_user
      tags = resolve_tags_from_params params,attr, use_autocomplete
      tag_as_user_with tags,attr,owner
    end

    def tag_with_params params,attr="tag",use_autocomplete=true,owner=User.current_user
      tags = resolve_tags_from_params params,attr, use_autocomplete
      tag_with tags,attr,owner
    end

    def resolve_tags_from_params params,attr,use_autocomplete=true
      tags=[]
      if use_autocomplete
        selected_key = "#{attr}_autocompleter_selected_ids".to_sym
        unrecognized_key = "#{attr}_autocompleter_unrecognized_items".to_sym
        params[selected_key].each do |selected_id|
        tag=TextValue.find(selected_id)
        tags << tag.text
        end unless params[selected_key].nil?
        params[unrecognized_key].each do |item|
          tags << item
        end unless params[unrecognized_key].nil?
      else
        tags << params[:annotation][:value]
      end
      tags
    end

    def tag_as_user_with tags, attr="tag", owner=User.current_user
      tag_with tags,attr,owner,true
    end

    def tag_with tags, attr="tag", owner=User.current_user,owned_tags_only=false

      #FIXME: yuck! - this is required so that self has an id and can be assigned to an Annotation.annotatable
      return if self.new_record? && !self.save

      current = self.annotations_with_attribute(attr)
      current = current.select{|c| c.source==owner} if owned_tags_only
      for_removal = []
      current.each do |cur|
        unless tags.include?(cur.value.text)
          for_removal << cur
        end
      end

      tags.each do |tag|
        exists = TextValue.find(:all, :conditions=>{:text=>tag})
        # text_value exists for this attr
        if !exists.empty?

          # isn't already used as an annotation for this entity
          if owned_tags_only
            matching = Annotation.for_annotatable(self.class.name, self.id).with_attribute_name(attr).by_source(owner.class.name,owner.id).select { |a| a.value.text==tag }
          else
            matching = Annotation.for_annotatable(self.class.name, self.id).with_attribute_name(attr).select { |a| a.value.text==tag }
          end


          if matching.empty?
            annotation = Annotation.new(:source => owner,
                                        :annotatable => self,
                                        :attribute_name => attr,
                                        :value => exists.first)
            annotation.save!
          end
        else
          annotation = Annotation.new(:source => owner,
                                      :annotatable => self,
                                      :attribute_name => attr,
                                      :value => tag)
          annotation.save!
        end
      end
      for_removal.each do |annotation|
        annotation.destroy
      end

    end

    def searchable_tags
      tags_as_text_array
    end

    def tags_as_text_array
      self.annotations.include_values.collect{|a| a.value.text}
    end

  end
end