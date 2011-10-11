# ActsAsAnnotationValue
module Annotations
  module Acts #:nodoc:
    module AnnotationValue #:nodoc:

      def self.included(base)
        base.send :extend, ClassMethods  
      end

      module ClassMethods
        def acts_as_annotation_value(options)
          cattr_accessor :ann_value_content_field, :is_annotation_value
          
          if options[:content_field].blank?
            raise ArgumentError.new("Must specify the :content_field option that will be used as the field for the content")
          end
          
          self.ann_value_content_field = options[:content_field] 
          
          has_many :annotations,
                   :as => :value
                   
          has_many :annotation_value_seeds,
                   :as => :value
           
          __send__ :extend, SingletonMethods
          __send__ :include, InstanceMethods
          
          self.is_annotation_value = true
        end
      end
      
      # Class methods added to the model that has been made acts_as_annotation_value (the mixin target class).
      module SingletonMethods
        
        # This class level method is used to determine whether there is an existing 
        # annotation on an annotatable object, regardless of source. So, it is used to 
        # determine whether a "duplicate" exists (but the notion of "duplicate"
        # may vary between annotation value classes).
        #
        # This method may be redefined in your model.
        # A default implementation is provided that may suffice for most cases.
        # But note that it makes certain assumptions that may not be valid for all 
        # kinds of annotation value models:
        # - the joins for the value model use +ActiveRecord::Base::table_name+ to
        #   determine the name of the table to join on.
        # - the field used make the comparison on the content is defined by the 
        #   ':content_field' option passed into acts_as_annotation_value.
        # 
        # Note: A precondition to this method is: this expects a valid 
        # +annotation+ object (i.e. one that contains a valid +value+ 
        # object, valid +annotatable+ object, valid +attribute+ and so on).
        def has_duplicate_annotation?(annotation)
          return false unless annotation.value.is_a?(self)
          
          val_table_name = self.table_name
          
          existing = Annotation.find(:all,
                                     :joins => "INNER JOIN annotation_attributes ON annotation_attributes.id = annotations.attribute_id
                                                INNER JOIN #{val_table_name} ON annotations.value_type = '#{self.name}' AND #{val_table_name}.id = annotations.value_id",
                                     :conditions => [ "annotations.annotatable_type = ? AND 
                                                       annotations.annotatable_id = ? AND
                                                       annotation_attributes.name = ? AND
                                                       #{val_table_name}.#{self.ann_value_content_field} = ?",
                                                       annotation.annotatable_type,
                                                       annotation.annotatable_id,
                                                       annotation.attribute_name,
                                                       annotation.value.send(self.ann_value_content_field) ])
      
          if existing.length == 0 || existing.first.id == annotation.id
            return false
          else
            return true
          end
          
        end

        #A set of all values that have been used, or seeded, with one of the provided attribute names
        def with_attribute_names attributes
          attributes = Array(attributes)
          annotations = Annotation.with_attribute_names(attributes).with_value_type(self.name).include_values.collect{|ann| ann.value}
          seeds = AnnotationValueSeed.with_attribute_names(attributes).with_value_type(self.name).include_values.collect{|ann| ann.value}
          (annotations | seeds).uniq
        end
      end
      
      # This module contains instance methods
      module InstanceMethods

        #Whether this value exists with a given attribute name
        def has_attribute_name? attr
          !annotations.with_attribute_name(attr).empty? || !annotation_value_seeds.with_attribute_name(attr).empty?
        end

        #The total number of annotations that match one or more attribute names.
        def annotation_count attributes
          attributes = Array(attributes)
          annotations.with_attribute_names(attributes).count
        end
        
        # The actual content of the annotation value
        def ann_content
          self.send(self.class.ann_value_content_field)
        end
        
        # Set the actual content of the annotation value
        def ann_content=(val)
          self.send("#{self.class.ann_value_content_field}=", val)
        end

      end
      
    end
  end
end
