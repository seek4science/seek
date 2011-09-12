module Seek
  module Taggable

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
      self.annotations.collect{|a| a.value.text}
    end

  end
end