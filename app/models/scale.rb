class Scale < ActiveRecord::Base
  has_many :scalings, :dependent => :destroy

  # attr_accessible :image_name, :key, :pos, :title
  alias_attribute :name, :title

    default_scope -> { order("pos ASC") }

    validates_presence_of :title,:key,:image_name
    validates_uniqueness_of :title,:key,:image_name

    after_destroy :remove_annotations

    acts_as_annotation_value :content_field => :title

    def self.with_scale scale
      scale = Scale.find_by_id(scale) if scale.is_a?(Numeric)
      scale.assets

    end

    def assets
      self.annotations.with_attribute_name("scale").collect{|an| an.annotatable}
      #scalables = Scaling.where(["scale_id=?", self.id]).includes(:scalable).collect(&:scalable).compact.uniq
      #grouped_scalings = scalables.group_by { |scalable| scalable.class.name }
    end

    def image_path
      "scales/#{image_name}"
    end

    def text
      title
    end

    private

    def remove_annotations
      self.annotations.destroy_all
    end
end
