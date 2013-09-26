class Scale < ActiveRecord::Base
  attr_accessible :image_name, :key, :pos, :title

  default_scope order("pos ASC")

  validates_presence_of :title,:key,:image_name
  validates_uniqueness_of :title,:key,:image_name

  after_destroy :remove_annotations

  acts_as_annotation_value :content_field => :title

  def self.with_scale scale
    scale = Scale.find_by_id(scale) if scale.is_a?(Numeric)
    scale.annotations.with_attribute_name("scale").collect{|an| an.annotatable}
  end

  def image_path
    "scales/#{image_name}"
  end

  private

  def remove_annotations
    self.annotations.destroy_all
  end
end
