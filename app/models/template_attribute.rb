class TemplateAttribute < ApplicationRecord
  belongs_to :sample_controlled_vocab
  belongs_to :sample_attribute_type
  belongs_to :template, inverse_of: :template_attributes
  belongs_to :unit
  validates :title, presence: true

  before_save :default_pos

  # if not set, takes the next value for that sample type
  def default_pos
    self.pos ||= (self.class.where(template_id: template_id).maximum(:pos) || 0) + 1
  end
end
