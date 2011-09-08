module Seek
  module Taggable


    def annotate_with tags, attr="tag", owner=User.current_user

      current = self.annotations_with_attribute(attr)
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
          matching = Annotation.for_annotatable(self.class.name,self.id).with_attribute_name(attr).select{|a| a.value.text==tag}
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


  end
end