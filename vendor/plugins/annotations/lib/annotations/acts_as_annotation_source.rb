# ActsAsAnnotationSource
module Annotations
  module Acts #:nodoc:
    module AnnotationSource #:nodoc:

      def self.included(base)
        base.send :extend, ClassMethods  
      end

      module ClassMethods
        def acts_as_annotation_source
          has_many :annotations_by,
                   :class_name => "Annotation",
                   :as => :source, 
                   :order => 'updated_at ASC'
                   
          __send__ :extend, SingletonMethods
          __send__ :include, InstanceMethods
        end
      end
      
      # Class methods added to the model that has been made acts_as_annotation_source (the mixin target class).
      module SingletonMethods
        # Helper finder to get all annotations for an object of the mixin source type with the ID provided.
        # This is the same as +#annotations+ on the object, with the added benefit that the object doesnt have to be loaded.
        # E.g: +User.find_annotations_by(10)+ will give all annotations by User with ID 34.
        def annotations_by(id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Annotation.find(:all,
                          :conditions => { :source_type =>  obj_type, 
                                           :source_id => id },
                          :order => "updated_at DESC")
        end
        
        # Helper finder to get all annotations for all objects of the mixin source type, for the annotatable object provided.
        # E.g: +User.find_annotations_for('Book', 28)+ will give all annotations made by all Users for Book with ID 28. 
        def annotations_for(annotatable_type, annotatable_id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Annotation.find(:all,
                          :conditions => { :source_type => obj_type,
                                           :annotatable_type =>  annotatable_type, 
                                           :annotatable_id => annotatable_id },
                          :order => "updated_at DESC")
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Helper method to get latest annotations
        def latest_annotations(limit=nil)
          Annotation.find(:all,
                          :conditions => { :source_type =>  self.class.name, 
                                           :source_id => id },
                          :order => "updated_at DESC",
                          :limit => limit)
        end
        
        def annotation_source_name
          %w{ preferred_name display_name title name }.each do |w|
            return eval("self.#{w}") if self.respond_to?(w)
          end
          return "#{self.class.name}_#{self.id}"
        end

        # When used with the default style (:simple), returns a Hash of the +annotations_by+ values
        # grouped by attribute name.
        #
        # Example output:
        # {
        #   "Summary" => "Something interesting happens",
        #   "length" => 345,
        #   "Title" => "Harry Potter and the Exploding Men's Locker Room",
        #   "Tag" => [ "amusing rhetoric", "wizadry" ],
        #   "rating" => "4/5"
        # }
        def annotations_by_hash(style=:simple)
          h = { }

          unless self.annotations_by.blank?
            self.annotations_by.each do |a|
              if h.has_key?(a.attribute_name)
                case h[a.attribute_name]
                  when Array
                    h[a.attribute_name] << a.value_content
                  else
                    h[a.attribute_name] = [ h[a.attribute_name], a.value_content ]
                end
              else
                h[a.attribute_name] = a.value_content
              end
            end
          end

          return h
        end
      end
      
    end
  end
end
