class Scale < ApplicationRecord
  has_many :scalings, :dependent => :destroy

  # attr_accessible :image_name, :key, :pos, :title
  alias_attribute :name, :title

  default_scope -> { order("pos ASC") }

  validates_presence_of :title,:key,:image_name
  validates_uniqueness_of :title,:key,:image_name

  after_destroy :remove_annotations

  acts_as_annotation_value :content_field => :title

  def assets
    annotations.with_attribute_name("scale").collect{|an| an.annotatable}
    #scalables = Scaling.where(["scale_id=?", self.id]).includes(:scalable).collect(&:scalable).compact.uniq
    #grouped_scalings = scalables.group_by { |scalable| scalable.class.name }
  end

  def grouped_assets
    grouped = grouped_asset_ids
    grouped.each do |type, ids|
      grouped[type] = type.constantize.where(id: ids)
    end

    grouped
  end

  def grouped_asset_ids
    grouped = annotations.with_attribute_name("scale").group_by(&:annotatable_type)
    grouped.each do |type, annotations|
      grouped[type] = annotations.map(&:annotatable_id)
    end

    grouped
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
