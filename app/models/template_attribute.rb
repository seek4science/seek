class TemplateAttribute < ApplicationRecord
  include Seek::JSONMetadata::Attribute
  belongs_to :sample_controlled_vocab
  belongs_to :sample_attribute_type
  belongs_to :template, inverse_of: :template_attributes
  belongs_to :unit
  belongs_to :isa_tag
  belongs_to :linked_sample_type, class_name: 'SampleType'
  has_many :sample_attributes
  has_many :child_template_attributes, class_name: 'TemplateAttribute', foreign_key: 'parent_attribute_id'
  belongs_to :parent_attribute, class_name: 'TemplateAttribute', optional: true

  validates :title, presence: true

  before_save :default_pos

  def controlled_vocab?
    sample_attribute_type&.base_type == Seek::Samples::BaseType::CV
  end

  def allow_isa_tag_change?
    !inherited?
  end

  def inherited?
    parent_attribute_id.present?
  end

  def input_attribute?
    isa_tag.nil? && title&.downcase&.include?('input') && sample_attribute_type.seek_sample_multi?
  end

  private

  def default_pos
    self.pos ||= (self.class.where(template_id: template_id).maximum(:pos) || 0) + 1
  end
end
