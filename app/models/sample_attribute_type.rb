class SampleAttributeType < ApplicationRecord

  validates :title, :base_type, :regexp, presence: true
  validate :validate_allowed_type, :validate_regular_expression, :validate_resolution

  has_many :sample_attributes, inverse_of: :sample_attribute_type
  has_many :extended_metadata_attributes, inverse_of: :sample_attribute_type
  has_many :isa_template_attributes, class_name: 'TemplateAttribute', inverse_of: :sample_attribute_type

  before_save :set_defaults_attributes
  after_initialize :set_defaults_attributes

  scope :primitive_string_types, -> { where(base_type: 'String', regexp: '.*') }

  def validate_allowed_type
    unless Seek::Samples::BaseType.valid?(base_type)
      errors.add(:base_type, 'Not a valid base type')
    end
  end

  def self.allowed_base_types
    BASE_TYPES
  end

  def self.default
    primitive_string_types.first
  end

  def default?
    self == self.class.default
  end

  def as_json(_options = nil)
    { title: title, base_type: base_type, regexp: regexp }
  end

  def set_defaults_attributes
    self.regexp ||= '.*'
  end

  def validate_regular_expression
    regular_expression
  rescue RegexpError
    errors.add(:regexp, 'Not a valid regular expression')
  end

  def regular_expression
    /#{regexp}/m
  end

  def validate_resolution
    !resolution.present? || (resolution.include? '\\')
  end

  def controlled_vocab?
    [Seek::Samples::BaseType::CV, Seek::Samples::BaseType::CV_LIST].include?(base_type)
  end

  def seek_cv_list?
    base_type == Seek::Samples::BaseType::CV_LIST
  end

  def linked_extended_metadata?
    base_type == Seek::Samples::BaseType::LINKED_EXTENDED_METADATA
  end

  def linked_extended_metadata_multi?
    base_type == Seek::Samples::BaseType::LINKED_EXTENDED_METADATA_MULTI
  end

  def seek_sample?
    base_type == Seek::Samples::BaseType::SEEK_SAMPLE
  end

  def seek_sample_multi?
    base_type == Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
  end

  def seek_strain?
    base_type == Seek::Samples::BaseType::SEEK_STRAIN
  end

  def seek_data_file?
    base_type == Seek::Samples::BaseType::SEEK_DATA_FILE
  end


end
