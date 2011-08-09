module Acts
  module Scalable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_scalable?
      self.class.is_scalable?

    end

    module ClassMethods
      def acts_as_scalable

        before_save :set_scaler
        has_many :scales,:through=>:scalings,:source=>:scale
        has_many :scalings,:as => :scalable, :dependent => :destroy, :include => :scale

        class_eval do
          extend Acts::Scalable::SingletonMethods
        end
        include Acts::Scalable::InstanceMethods
      end

      def is_scalable?
          include? Acts::Scalable::InstanceMethods
      end


    end
    module SingletonMethods

    end
    module InstanceMethods
      def set_scaler
        scalings.each do |s|
          s.person = User.current_user.person
          s.save!
        end
      end
      #def scales=  scale_list=[]
      #    existing_scales = self.scales
      #    new_scalings =[]
      #    scale_list.each do |scale|
      #       new_scalings << scale unless existing_scales.include? scale
      #    end
      #
      #    new_scalings.each do |scale|
      #      scalings.create!(:scale_id => scale.id, :person => User.current_user.person, :taggable => self)
      #    end
      #
      #
      #end
      #def scales
      #  scalings.collect(&:scale)
      #end
      #
      #def scale_ids=  ids=[]
      #    ids = ids.compact.reject(& :empty?).collect(& :to_i)
      #    old_scale_ids = scale_ids - ids
      #    Acts::Scalable::Scaling.find(:all,:conditions=>{:scale_id=>old_scale_ids,:scalable_id=>self.id,:scalable_type=>self.class.name}).each(&:destroy) unless old_scale_ids.blank?
      #
      #    new_scale_ids = ids - scale_ids
      #    new_scale_ids.each do |scale_id|
      #      scalings.build(:scale_id=>scale_id,:person => User.current_user.person,:scalable=>self) if Acts::Scalable::Scaling.all.detect{|scaling|scaling.scale_id==scale_id and scaling.scalable==self}.nil?
      #    end
      #end
      #
      #def scale_ids
      #    scales.collect(& :id)
      #end

    end


  end



end

#ActsAsTaggableOn::Tag.class_eval do
#   def is_scale?
#     Seek::Config.scales.include? name
#   end
#end

ActiveRecord::Base.class_eval do
  include Acts::Scalable
end
