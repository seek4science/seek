class Scale < ActiveRecord::Base
  attr_accessible :image_name, :key, :pos, :title

  default_scope order("pos ASC")

  validates_presence_of :title,:key,:image_name
  validates_uniqueness_of :title,:key,:image_name

  acts_as_annotation_value :content_field => :title
end
