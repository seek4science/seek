class TemplateAttribute < ApplicationRecord
  belongs_to :sample_controlled_vocab
  belongs_to :sample_attribute_type
  belongs_to :template, inverse_of: :template_attributes
  validates :title, presence: true
end
