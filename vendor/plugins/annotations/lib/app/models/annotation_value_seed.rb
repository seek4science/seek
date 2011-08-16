class AnnotationValueSeed < ActiveRecord::Base
  validates_presence_of :attribute_id,
                        :value_type,
                        :value_id
  
  belongs_to :value,
             :polymorphic => true
             
  belongs_to :attribute,
             :class_name => "AnnotationAttribute",
             :foreign_key => "attribute_id"
  
  def self.find_by_attribute_name(attr_name)
    return [] if attr_name.blank?
          
    AnnotationValueSeed.find(:all,
                             :joins => [ :attribute ],
                             :conditions => { :annotation_attributes => { :name => attr_name } },
                             :order => "created_at DESC")
  end
end