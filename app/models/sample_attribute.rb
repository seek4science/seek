class SampleAttribute < ActiveRecord::Base
  attr_accessible :sample_attribute_type_id, :title, :required, :sample_attribute_type, :pos, :sample_type_id,
                  :_destroy, :sample_type, :unit, :unit_id, :is_title, :template_column_index

  belongs_to :sample_attribute_type
  belongs_to :sample_type, inverse_of: :sample_attributes
  belongs_to :unit

  validates :title, :sample_attribute_type, presence: true
  validates :sample_type, presence: true

  before_save :generate_accessor_name
  before_save :default_pos, :check_required_against_is_title

  scope :title_attributes, where(is_title: true)

  def title= title
    super
    generate_accessor_name
    self.title
  end

  def validate_value?(value)
    return false if required? && value.blank?
    (value.blank? && !required?) || sample_attribute_type.validate_value?(value)
  end

  # the name for the sample accessor based on the attribute title, spaces are replaced with underscore, and all downcase
  # if there is a clash with a sample method then _ is prepended
  def generate_accessor_name
    name = parameterised_title
    name += '_' while (Sample.attribute_method?(name) || Sample.private_method_defined?(name))
    self.accessor_name = name
  end

  def parameterised_title
    title.parameterize.underscore
  end

  def required?
    super || is_title?
  end

  private

  # if not set, takes the next value for that sample type
  def default_pos
    self.pos ||= (self.class.where(sample_type_id: sample_type_id).maximum(:pos) || 0) + 1
  end

  def check_required_against_is_title
    self.required = required? || is_title?
    true
  end
end
